import socket
import sys

HOST = "127.0.0.1"
PORT = 5566

if len(sys.argv) < 2:
    print("需要提供脚本路径")
    sys.exit(1)

filepath = sys.argv[1]

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((HOST, PORT))
    s.sendall((filepath + "\n").encode("utf-8"))
    data = s.recv(4096)

print("Blender 返回:", data.decode("utf-8").strip())
