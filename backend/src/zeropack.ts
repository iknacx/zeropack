import type { Socket } from "bun";

export interface FieldSchema {
  type: number;
  offset: number;
  length: number;
  name: string;
}

export interface StructSchema {
  id: number;
  count: number;
  size: number;
  name: string;
  fields: FieldSchema[];
}

export interface ActionSchema {
  id: number;
  type: number;
  is_array: boolean;
  name: string;
}

export interface DecodedPacket<T = unknown> {
  action: ActionSchema;
  data: T;
  raw: Buffer;
}

export interface ZeroPackHandlers {
  onHandshake?: (zp: ZeroPackSession) => void;
  onPacket?: (packet: DecodedPacket, zp: ZeroPackSession) => void;
}

const PRIM_SIZES: Record<number, number> = {
  0: 0, 1: 1, 2: 2, 3: 4, 4: 8,
  5: 1, 6: 2, 7: 4, 8: 8, 9: 4,
  10: 8, 11: 1, 12: 4,
};

export class ZeroPackSession {
  private buffer: Buffer = Buffer.alloc(0);
  private ready = false;

  public pool_size = 0;
  public flags = 0;

  public structs = {
    by_id: {} as Record<number, StructSchema>,
    by_name: {} as Record<string, StructSchema>,
    list: [] as StructSchema[],
  };

  public actions = {
    by_id: {} as Record<number, ActionSchema>,
    by_name: {} as Record<string, ActionSchema>,
    list: [] as ActionSchema[],
  };

  constructor(
    private socket: Socket<ZeroPackSession>,
    private handlers: ZeroPackHandlers = {}
  ) { }

  public feed(chunk: Buffer) {
    this.buffer = Buffer.concat([this.buffer, chunk]);

    if (!this.ready) {
      if (!this.processHandshake()) return;
    }

    this.processStream();
  }

  public send(action_name: string, data?: any) {
    const act = this.actions.by_name[action_name];
    if (!act) throw new Error(`Acción desconocida: ${action_name}`);

    // 1. Acción Void
    if (act.type === 0) {
      this.socket.write(this.buildPacket(act.id, 0, false, 0));
      return;
    }

    // 2. Acción de Array
    if (act.is_array) {
      const arr = Array.isArray(data) ? data : Array.from(data ?? []);
      const size = this.getTypeSize(act.type);
      const payload = Buffer.alloc(arr.length * size);

      for (let i = 0; i < arr.length; i++) {
        this.writeValue(payload, act.type, i * size, arr[i]);
      }

      this.socket.write(this.buildPacket(act.id, act.type, true, arr.length, payload));
      return;
    }

    // 3. Acción de Struct
    const struct_def = this.structs.by_id[act.type];
    if (struct_def) {
      const payload = this.encodeStruct(struct_def, data ?? {});
      this.socket.write(this.buildPacket(act.id, struct_def.id, false, 0, payload));
      return;
    }

    // 4. Primitivo suelto
    const payload = Buffer.alloc(this.getTypeSize(act.type));
    this.writePrimitive(payload, act.type, 0, data ?? 0);
    this.socket.write(this.buildPacket(act.id, act.type, false, 0, payload));
  }

  private processHandshake(): boolean {
    let cursor = 0;

    const read_c_string = () => {
      let end = cursor;
      while (end < this.buffer.length && this.buffer[end] !== 0) end++;
      if (end >= this.buffer.length) throw new RangeError("incomplete chunk");
      const str = this.buffer.toString("utf8", cursor, end);
      cursor = end + 1;
      return str;
    };

    try {
      if (this.buffer.length < 8) return false;

      const magic = this.buffer.readUInt8(cursor++);
      this.flags = this.buffer.readUInt8(cursor++);

      if (magic !== 0x5a) {
        console.error("Invalid magic byte:", magic);
        this.socket.close();
        return false;
      }

      this.pool_size = this.buffer.readUInt16LE(cursor); cursor += 2;
      const type_count = this.buffer.readUInt16LE(cursor); cursor += 2;
      const action_count = this.buffer.readUInt16LE(cursor); cursor += 2;

      for (let i = 0; i < type_count; i++) {
        const id = this.buffer.readUInt8(cursor++);
        const count = this.buffer.readUInt8(cursor++);
        const size = this.buffer.readUInt16LE(cursor); cursor += 2;
        const name = read_c_string();

        const fields: FieldSchema[] = [];
        for (let j = 0; j < count; j++) {
          const type = this.buffer.readUInt8(cursor++);
          const offset = this.buffer.readUInt16LE(cursor); cursor += 2;
          const length = this.buffer.readUInt16LE(cursor); cursor += 2;
          const fname = read_c_string();
          fields.push({ type, offset, length, name: fname });
        }

        const struct_def: StructSchema = { id, count, size, name, fields };
        this.structs.by_id[id] = struct_def;
        this.structs.by_name[name] = struct_def;
        this.structs.list.push(struct_def);
      }

      for (let id = 0; id < action_count; id++) {
        const type = this.buffer.readUInt8(cursor++);
        const is_array = this.buffer.readUInt8(cursor++) === 1;
        const name = read_c_string();

        const action: ActionSchema = { id, type, is_array, name };
        this.actions.by_id[id] = action;
        this.actions.by_name[name] = action;
        this.actions.list.push(action);
      }

      this.ready = true;
      this.buffer = this.buffer.subarray(cursor);

      this.handlers.onHandshake?.(this);
      return true;
    } catch (err) {
      if (err instanceof RangeError) return false;
      throw err;
    }
  }

  private processStream() {
    while (this.buffer.length >= 4) {
      const action_id = this.buffer.readUInt8(0);
      const type_id = this.buffer.readUInt8(1);
      const bitfield = this.buffer.readUInt16LE(2);
      const is_array = (bitfield & 1) === 1;
      const array_len = (bitfield >> 1) & 0x7fff;

      const elem_size = this.getTypeSize(type_id);
      const payload_len = is_array ? array_len * elem_size : elem_size;
      const total_len = 4 + payload_len;

      if (this.buffer.length < total_len) break;

      const raw = this.buffer.subarray(4, total_len);
      const action = this.actions.by_id[action_id] ?? {
        id: action_id,
        type: type_id,
        is_array,
        name: `UNKNOWN_${action_id}`,
      };

      const data = this.decodePayload(type_id, is_array, array_len, raw);
      this.handlers.onPacket?.({ action, data, raw }, this);

      this.buffer = this.buffer.subarray(total_len);
    }
  }

  private getTypeSize(type_id: number): number {
    if (type_id in PRIM_SIZES) return PRIM_SIZES[type_id]!;
    return this.structs.by_id[type_id]?.size ?? 0;
  }

  private buildPacket(
    action_id: number,
    type_id: number,
    is_array: boolean,
    array_len: number,
    payload?: Uint8Array
  ): Buffer {
    const hdr = Buffer.alloc(4);
    hdr.writeUInt8(action_id, 0);
    hdr.writeUInt8(type_id, 1);
    const bitfield = ((array_len & 0x7fff) << 1) | (is_array ? 1 : 0);
    hdr.writeUInt16LE(bitfield, 2);
    return payload ? Buffer.concat([hdr, payload]) : hdr;
  }

  private decodePayload(
    type_id: number,
    is_array: boolean,
    array_len: number,
    raw: Buffer
  ): unknown {
    if (type_id === 0 || raw.length === 0) return null;

    if (is_array) {
      const elem_size = this.getTypeSize(type_id);
      return Array.from({ length: array_len }, (_, i) =>
        this.readValue(raw, type_id, i * elem_size)
      );
    }

    return this.readValue(raw, type_id, 0);
  }

  private readValue(buf: Buffer, type_id: number, offset: number): unknown {
    const struct_def = this.structs.by_id[type_id];
    if (struct_def) {
      return this.readStruct(buf, struct_def, offset);
    }
    return this.readPrimitive(buf, type_id, offset);
  }

  private readStruct(
    buf: Buffer,
    struct_def: StructSchema,
    base_offset: number
  ): Record<string, unknown> {
    const obj: Record<string, unknown> = {};

    for (const f of struct_def.fields) {
      const field_offset = base_offset + f.offset;

      if (f.length > 0) {
        const elem_size = this.getTypeSize(f.type);
        obj[f.name] = Array.from({ length: f.length }, (_, i) =>
          this.readValue(buf, f.type, field_offset + i * elem_size)
        );
      } else {
        obj[f.name] = this.readValue(buf, f.type, field_offset);
      }
    }

    return obj;
  }

  private encodeStruct(
    struct_def: StructSchema,
    data: Record<string, any>
  ): Buffer {
    const buf = Buffer.alloc(struct_def.size);
    this.writeStruct(buf, struct_def, 0, data);
    return buf;
  }

  private writeValue(
    buf: Buffer,
    type_id: number,
    offset: number,
    val: any
  ): void {
    const struct_def = this.structs.by_id[type_id];
    if (struct_def) {
      this.writeStruct(buf, struct_def, offset, val ?? {});
    } else {
      this.writePrimitive(buf, type_id, offset, val);
    }
  }

  private writeStruct(
    buf: Buffer,
    struct_def: StructSchema,
    base_offset: number,
    data: Record<string, any>
  ): void {
    for (const f of struct_def.fields) {
      const val = data[f.name];
      if (val === undefined) continue;

      const field_offset = base_offset + f.offset;

      if (f.length > 0) {
        const arr = Array.isArray(val) ? val : Array.from(val ?? []);
        const size = this.getTypeSize(f.type);
        const count = Math.min(f.length, val.length);
        for (let i = 0; i < count; i++) {
          this.writeValue(buf, f.type, field_offset + i * size, arr[i]);
        }
      } else {
        this.writeValue(buf, f.type, field_offset, val);
      }
    }
  }

  private readPrimitive(buf: Buffer, type_id: number, offset: number): unknown {
    switch (type_id) {
      case 1: return buf.readUInt8(offset);
      case 2: return buf.readUInt16LE(offset);
      case 3: return buf.readUInt32LE(offset);
      case 4: return buf.readBigUInt64LE(offset);
      case 5: return buf.readInt8(offset);
      case 6: return buf.readInt16LE(offset);
      case 7: return buf.readInt32LE(offset);
      case 8: return buf.readBigInt64LE(offset);
      case 9: return buf.readFloatLE(offset);
      case 10: return buf.readDoubleLE(offset);
      case 11: return buf.readUInt8(offset) !== 0;
      default: return null;
    }
  }

  private writePrimitive(buf: Buffer, type_id: number, offset: number, val: any) {
    switch (type_id) {
      case 1: buf.writeUInt8(Number(val) & 0xff, offset); break;
      case 2: buf.writeUInt16LE(Number(val) & 0xffff, offset); break;
      case 3: buf.writeUInt32LE(Number(val) >>> 0, offset); break;
      case 4: buf.writeBigUInt64LE(BigInt(val), offset); break;
      case 5: buf.writeInt8(Number(val), offset); break;
      case 6: buf.writeInt16LE(Number(val), offset); break;
      case 7: buf.writeInt32LE(Number(val), offset); break;
      case 8: buf.writeBigInt64LE(BigInt(val), offset); break;
      case 9: buf.writeFloatLE(Number(val), offset); break;
      case 10: buf.writeDoubleLE(Number(val), offset); break;
      case 11: buf.writeUInt8(val ? 1 : 0, offset); break;
    }
  }
}
