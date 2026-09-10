import { listen, type Socket } from "bun";

interface FieldSchema {
  type: number;
  offset: number;
  length: number;
  name: string;
};

interface StructSchema {
  id: number;
  count: number;
  size: number;
  name: string;
  fields: FieldSchema[];
};

interface ActionSchema {
  type: number;
  is_array: number;
  name: string;
}

class ZeroPackDecoder {
  private buffer: Buffer = Buffer.alloc(0);
  private loaded: boolean = false;

  private pool_size: number = 0;

  constructor(private socket: Socket<ZeroPackDecoder>) { }

  private structs = {
    byId: {} as Record<number, StructSchema>,
    byName: {} as Record<string, StructSchema>,
    length: 0,
  };
  private actions = {
    byId: {} as Record<number, ActionSchema>,
    byName: {} as Record<string, ActionSchema>,
    length: 0,
  };

  public feed(chunk: Buffer) {
    this.buffer = Buffer.concat([this.buffer, chunk]);
    if (!this.loaded) return this.processHandshake();
    this.processStream();
  }

  private processHandshake() {
    let cursor = 0;
    try {
      if (this.buffer.length < 8) return;

      const magic = this.buffer.readUInt8(cursor++);
      const flags = this.buffer.readUInt8(cursor++);

      if (magic != 0x5a) {
        console.error("Invalid magic");
        this.socket.close();
        return;
      }

      this.pool_size = this.buffer.readUInt16LE(cursor);
      cursor += 2;
      this.structs.length = this.buffer.readUInt16LE(cursor);
      cursor += 2;
      this.actions.length = this.buffer.readUInt16LE(cursor);
      cursor += 2;


      for (let i = 0; i < this.structs.length; i++) {
        const id = this.buffer.readUInt8(cursor++);
        const count = this.buffer.readUInt8(cursor++);
        const size = this.buffer.readUInt16LE(cursor);
        cursor += 2;

        let end = cursor;
        while (end < this.buffer.length && this.buffer[end] !== 0) end++;
        if (end >= this.buffer.length) throw new RangeError("incomplete chunk");

        const sname = this.buffer.toString('utf8', cursor, end);
        cursor = end + 1;

        let struct_def: StructSchema = { id, count, size, name: sname, fields: [] };
        this.structs.byId[id] = struct_def;
        this.structs.byName[sname] = struct_def;

        for (let j = 0; j < count; j++) {
          const type = this.buffer.readUInt8(cursor++);
          const offset = this.buffer.readUInt16LE(cursor);
          cursor += 2;
          const length = this.buffer.readUInt16LE(cursor);
          cursor += 2;

          let end = cursor;
          while (end < this.buffer.length && this.buffer[end] !== 0) end++;
          if (end >= this.buffer.length) throw new RangeError("incomplete chunk");

          const fname = this.buffer.toString('utf8', cursor, end);
          cursor = end + 1;

          struct_def.fields.push({ type, offset, length, name: fname })
        }
      }

      for (let id = 0; id < this.actions.length; id++) {
        const type = this.buffer.readUint8(cursor++);
        const is_array = this.buffer.readUint8(cursor++);

        let end = cursor;
        while (end < this.buffer.length && this.buffer[end] !== 0) end++;
        if (end >= this.buffer.length) throw new RangeError("incomplete chunk");

        const name = this.buffer.toString('utf8', cursor, end);
        cursor = end + 1;

        const action: ActionSchema = { type, is_array, name };
        this.actions.byId[id] = action;
        this.actions.byName[name] = action;
      }


    } catch (err) {
      if (err instanceof RangeError) return;
      throw err;
    }

    this.buffer = this.buffer.subarray(cursor);

    console.log(this.structs.byName)
    console.log(this.actions.byName)
    console.log(`Types: ${this.structs.length} | Actions: ${this.actions.length}`)
  }

  private processStream() {
    while (this.buffer.length > 0) { }
  }
};

const server = listen<ZeroPackDecoder>({
  hostname: '0.0.0.0',
  port: 1234,

  socket: {
    open(socket) {
      console.log("device connected");
      socket.data = new ZeroPackDecoder(socket);
    },

    data(socket, data) {
      socket.data.feed(data);
    },

    close(_socket) {
      console.log("device disconnected");
    },

    error(_socket, error) {
      console.error("socket error:", error);
    }
  }
});

console.log(`Server listening on ${server.hostname}:${server.port}`)
