import email
import queue
import socketserver
import threading


class SmtpTestSink:
    def __init__(self, port=1026):
        self.messages = queue.Queue()
        messages = self.messages

        class Handler(socketserver.StreamRequestHandler):
            def reply(self, text):
                self.wfile.write((text + "\r\n").encode("ascii"))
                self.wfile.flush()

            def handle(self):
                self.reply("220 localhost test SMTP")
                while line := self.rfile.readline():
                    command = line.decode("ascii", errors="replace").strip().upper()
                    if command.startswith(("EHLO", "HELO")):
                        self.reply("250 localhost")
                    elif command.startswith(("MAIL FROM:", "RCPT TO:", "RSET", "NOOP")):
                        self.reply("250 OK")
                    elif command == "DATA":
                        self.reply("354 End with a dot")
                        content = []
                        while data := self.rfile.readline():
                            if data == b".\r\n":
                                break
                            content.append(data[1:] if data.startswith(b"..") else data)
                        messages.put(email.message_from_bytes(b"".join(content)))
                        self.reply("250 Accepted for local testing")
                    elif command == "QUIT":
                        self.reply("221 Bye")
                        break
                    else:
                        self.reply("502 Unsupported command")

        self.server = socketserver.ThreadingTCPServer(("127.0.0.1", port), Handler)
        self.server.daemon_threads = True

    def start(self):
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def next_body(self):
        message = self.messages.get(timeout=10)
        return message.get_payload(decode=True).decode(message.get_content_charset() or "utf-8")

    def close(self):
        self.server.shutdown()
        self.server.server_close()
