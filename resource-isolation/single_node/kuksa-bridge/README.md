# KUKSA Bridge - Resource Isolation (Single Node)

KUKSA databroker subscriber running on a single node.
Receives button events and triggers CPU workload via shell scripts.

## Overview

This bridge subscribes to the `Vehicle.Cabin.ResourceIsolation.ButtonPressed` signal from the local KUKSA databroker.
When a button press is detected, it toggles the `stress-ng` workload to simulate CPU load.

```
┌─────────────────┐     ┌─────────────────┐
│  KUKSA Broker   │────▶│  KUKSA Bridge   │
│  (Port 55556)   │     │  (this)         │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   stress-ng     │
                        │   (CPU Load)    │
                        └─────────────────┘
```

All components run on the same host, so the bridge connects to the databroker over `127.0.0.1`.

## Configuration

Container settings are managed via the `.env` file.

```bash
# KUKSA Databroker Configuration
KUKSA_HOST=127.0.0.1
KUKSA_PORT=55556
KUKSA_PROTOCOL=grpc

# Shell scripts for toggle mode
TRIGGER_ON_SCRIPT=/app/script/trigger-on.sh
TRIGGER_OFF_SCRIPT=/app/script/trigger-off.sh
```

## Build

```bash
cd resource-isolation/single_node/kuksa-bridge
sudo podman build -t localhost/resiso-kuksa-bridge:latest .
```

## Run

```bash
sudo podman run --rm -d \
  --name resiso-kuksa-bridge \
  --network host \
  --privileged \
  -v "$PWD/.env:/app/.env:ro" \
  -v "$PWD/script:/app/script:ro" \
  -e PYTHONUNBUFFERED=1 \
  localhost/resiso-kuksa-bridge:latest
```

## Logs

```bash
# Real-time log monitoring
sudo podman logs resiso-kuksa-bridge -f

# Recent logs
sudo podman logs resiso-kuksa-bridge --tail=20
```

## Behavior

1. **KUKSA Databroker Connection**
   - Host: `127.0.0.1` (local databroker)
   - Port: `55556` (resource-isolation databroker)
   - Signal: `Vehicle.Cabin.ResourceIsolation.ButtonPressed`

2. **Button Event Handling**
   - Button PRESSED (toggle ON) → Execute `trigger-on.sh`
   - Button PRESSED (toggle OFF) → Execute `trigger-off.sh`

3. **Workload Control**
   - ON: `stress-ng --cpu 0 --cpu-method all --timeout 0`
   - OFF: `killall -9 stress-ng`

## Shell Scripts

### trigger-on.sh
- Kills any existing stress-ng processes
- Starts stress-ng in the background
- Uses all CPU cores with various stress methods

### trigger-off.sh
- Terminates all stress-ng processes
- Verifies clean termination

## Notes

- The bridge runs in toggle mode: each button press alternates ON/OFF
- `stress-ng` runs in the background, detached from the bridge process
- `.env` changes take effect on the next button event (no restart needed)
- Requires `--privileged` for process management on the host

