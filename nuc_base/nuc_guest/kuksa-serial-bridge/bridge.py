import serial, sys, re
from kuksa_client import KuksaClientThread as KuksaClient
from kuksa_client.grpc import Datapoint
import threading
import queue
import json

PORT_STICK = "/dev/arduino_joystick"
PORT_LED = "/dev/arduino_led"
BAUD = 115200

def parse_x_btn(line: str):
    parts = [p.strip() for p in line.split(',')]
    if len(parts) == 4 and parts[1].isdigit() and parts[3] in ("0", "1"):
        x = int(parts[1])
        btn = int(parts[3])
        if 0 <= x <= 1023:
            return x, btn

    nums = [int(m.group()) for m in re.finditer(r'[-+]?\d+', line)]
    xs = [n for n in nums if 0 <= n <= 1023]
    btns = [n for n in nums if n in (0,1)]
    x = xs[-1] if xs else None
    btn = btns[-1] if btns else None
    return x, btn

def extract_btn(line: str):
    last = None
    for ch in line:
        if ch in ("0", "1"):
            last = int(ch)
    return last

def recv_to_databroker(client):
    try:
        a = client.getValue("Vehicle.Body.Lights.DirectionIndicator.Left.IsSignaling")
        b = client.getValue("Vehicle.Body.Lights.DirectionIndicator.Right.IsSignaling")
        c = client.getValue("Vehicle.Body.Lights.Brake.IsActive")
        print(f"a {a}, b {b}, c {c}")
    except Exception as e:
        print(f"Databroker setValue error: {e}", file=sys.stderr)

def databroker_worker(client):
    while True:
        try:
            recv_to_databroker(client)
        except Exception as e:
            print(f"Databroker send error: {e}", file=sys.stderr)

def main():
        client = KuksaClient(config={'protocol': 'grpc', 'ip': '192.168.1.2', 'port': 55555, 'insecure': True})
        #client = KuksaClient(config={'url': 'grpc://192.168.1.2:55555', 'insecure': True})
        client.start()

        while True:
            recv_to_databroker(client)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Stopped.")
        sys.exit(0)
