bl_info = {
    "name": "External Script Runner (Socket)",
    "author": "AHK + Blender",
    "version": (1, 0),
    "blender": (3, 0, 0),
    "location": "Socket Server",
    "category": "System",
}

import bpy
import socket
import threading
import os

HOST = "127.0.0.1"
PORT = 5566   # 你可以改端口

def run_external_script(filepath):
    if not os.path.exists(filepath):
        print(f"[External Runner] File not found: {filepath}")
        return
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            code = f.read()
        exec(code, {"__name__": "__main__"})
        print(f"[External Runner] Executed {filepath}")
    except Exception as e:
        print(f"[External Runner] Error: {e}")

def socket_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind((HOST, PORT))
        s.listen()
        print(f"[External Runner] Listening on {HOST}:{PORT}")
        while True:
            conn, addr = s.accept()
            with conn:
                data = conn.recv(4096)
                if not data:
                    continue
                filepath = data.decode("utf-8").strip()
                run_external_script(filepath)
                conn.sendall(b"OK\n")


server_thread = None

def register():
    global server_thread
    server_thread = threading.Thread(target=socket_server, daemon=True)
    server_thread.start()
    print("[External Runner] Server started.")

def unregister():
    print("[External Runner] Server stopped.")
