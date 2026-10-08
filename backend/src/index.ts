import { listen } from "bun";
import readline from "node:readline";
import { ZeroPackSession } from "./zeropack";

let active_session: ZeroPackSession | null = null;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: "zp> ",
});

rl.on("line", (line) => {
  const parts = line.trim().split(/\s+/);
  const cmd = parts[0]?.toLowerCase();

  if (!cmd || !active_session) {
    rl.prompt();
    return;
  }

  if (cmd === "on") {
    active_session.send("ACTION_LED_ON");
  } else if (cmd === "off") {
    active_session.send("ACTION_LED_OFF");
  } else if (cmd === "rgb") {
    const [r = 0, g = 0, b = 0] = parts.slice(1).map(Number);
    active_session.send("ACTION_LED_COLOR", { r, g, b });
  } else if (cmd === "echo") {
    active_session.send("ACTION_ECHO", line.trim().slice(4).trim());
  }

  rl.prompt();
});

const server = listen<ZeroPackSession>({
  hostname: "0.0.0.0",
  port: 1234,
  socket: {
    open(socket) {
      console.log("\nDevice connected");
      socket.data = new ZeroPackSession(socket, {
        onHandshake(zp) {
          active_session = zp;
          console.log(zp.structs.by_name);
          console.log(zp.actions.by_name);
          console.log(
            `Types: ${zp.structs.list.length} | Actions: ${zp.actions.list.length}`
          );
          rl.prompt();
        },
        onPacket({ action, data }) {
          console.log(`\n[${action.name}] ->`, data);
          rl.prompt();
        },
      });
    },
    data(socket, data) {
      socket.data.feed(data);
    },
    close() {
      console.log("\nDevice disconnected");
      active_session = null;
    },
    error(_socket, error) {
      console.error("socket error:", error);
    },
  },
});

console.log(`Server listening on ${server.hostname}:${server.port}`);
