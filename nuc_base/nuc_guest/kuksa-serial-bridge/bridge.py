import serial
import sys
import threading
import queue
import json
import time
from kuksa_client import KuksaClientThread
from kuksa_client.grpc import Datapoint

def recv_to_databroker(client):
    try:
        #l = client.getValue("Vehicle.Body.Lights.DirectionIndicator.Left.IsSignaling")
        #r = client.getValue("Vehicle.Body.Lights.DirectionIndicator.Right.IsSignaling")
        b = client.getValue("Vehicle.Body.Lights.Brake.IsActive")
        # b is {'value': 'ACTIVE'} or {'value': 'INACTIVE'} dict or JSON
        if isinstance(b, str):
            b = json.loads(b)
        val = b.get('value') if isinstance(b, dict) else None
        if val == 'ACTIVE':
            return True
        elif val == 'INACTIVE':
            return False
        else:
            return None
    except Exception as e:
        print(f"Databroker getValue error: {e}", file=sys.stderr)
        return None

def main():
    client = KuksaClientThread(config={'protocol': 'grpc', 'ip': '192.168.1.2', 'port': 55555, 'insecure': True})
    #client = KuksaClientThread(config={'url': 'grpc://192.168.1.2:55555', 'insecure': True})
    client.start()

    while True:
        isBrake = recv_to_databroker(client)
        print(f"isBrake: {isBrake}")
        time.sleep(0.1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Stopped.")
        sys.exit(0)
