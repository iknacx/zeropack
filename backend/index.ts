import { listen } from "bun";

const server = listen({
  hostname: '0.0.0.0',
  port: 1234,

  socket: {
    open(_socket) {
      console.log("device connected");
    },

    data(_socket, data) {
      console.log("received data:", data);
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
