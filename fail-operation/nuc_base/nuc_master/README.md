# Fail Operation Demo - NUC Master

This folder contains the NUC Master setup for the fail-operation demonstration.

## Prerequisites

### Required Docker Images

The following Docker images must be built beforehand:

- `failop-serial-bridge:latest` - Bridge connecting Arduino and KUKSA/Pullpiri
- `quay.io/eclipse-kuksa/kuksa-databroker:0.6.0` - KUKSA databroker (official image)

### Build Docker Images

```bash
# Build Serial bridge image
cd /home/lge/work/sdv-blueprint/fail-operation/nuc_base/nuc_master
docker compose build failop-serial-bridge
```

**Verify:**
```bash
docker images | grep failop-serial-bridge
# failop-serial-bridge   latest   ...
```

KUKSA databroker is automatically pulled from docker-compose.yml.

## Arduino Setup

See [arduino](./arduino/README.md) for details

**Summary:**
1. Fix device path with udev rules configuration
2. Compile and upload Arduino firmware
3. 3 boards: Joystick, LED, Gear

## Hardware Setup

- **3 Arduino UNO R4 WiFi boards:**
  - `ardn_stick` - Joystick with button (input)
  - `ardn_led` - NeoPixel LED strip (output)
  - `ardn_gear` - Rotary encoder with LED ring (input)

## Architecture

### Data Flow

1. **Joystick Button → LED + KUKSA**
   - `ardn_stick` detects button press/release
   - Sends signal to `bridge.py`
   - `bridge.py` forwards to:
     - Local `ardn_led` Arduino (GREEN on press, OFF on release)
     - KUKSA databroker (for Guest to receive)

2. **Rotary Encoder → Pullpiri**
   - `ardn_gear` detects rotation (CW/CCW)
   - `bridge.py` manages state-based filtering:
     - state=0 or -1: Only CW allowed → LAUNCH
     - state=1: Only CCW allowed → STOP
     - Invalid direction → RED LED
   - Sends YAML artifact to Pullpiri via HTTP API (`192.168.0.3:47099/api/artifact`)

## Components

### Arduino Programs

- `ardn_stick/ardn_stick.ino` - Joystick button detection
- `ardn_led/ardn_led.ino` - LED controller (GREEN/RED/OFF)
- `ardn_gear/ardn_gear.ino` - Rotary encoder with state machine

### Python Bridge

- `serial/bridge.py` - Main bridge connecting Arduino ↔ KUKSA ↔ Pullpiri
  - Main Thread: Joystick → DataBroker + LED Control
  - Thread-DB: DataBroker worker (queue consumer)
  - Thread-Gear: Gear → YAML artifacts (CW/CCW)

### Pullpiri YAML

- `pullpiri-yaml/yaml/container-launch.yaml` - Launch containers
- `pullpiri-yaml/yaml/container-stop.yaml` - Stop containers

## Running

### 1. Start Docker Compose

```bash
cd /home/lge/work/sdv-blueprint/fail-operation/nuc_base/nuc_master
docker compose up -d
```

**Verify:**
```bash
docker compose ps
# NAME                   IMAGE                                          STATUS
# failop-databroker      quay.io/eclipse-kuksa/kuksa-databroker:0.6.0   Up
# failop-serial-bridge   failop-serial-bridge:latest                    Up
```

### 2. Check Logs

```bash
# Real-time logs
docker logs -f failop-serial-bridge

# Recent logs
docker logs --tail 50 failop-serial-bridge
```

**Expected startup logs:**
```
============================================================
Fail-Operation Serial Bridge
============================================================
Thread Architecture:
  [Main Thread]   Joystick (ttyACM2) → DataBroker + LED Control
  [Thread-DB]     DataBroker worker (queue consumer)
  [Thread-Gear]   Gear (ttyACM0) → YAML artifacts (CW/CCW)
============================================================
✓ Ready to send signals
[Thread-Gear] Monitor started: /dev/arduino_gear
[Main-Joystick] Monitor started: /dev/arduino_joystick
[Main-LED] Monitor started: /dev/arduino_led
```

### 3. Test Operation

**Joystick Test:**
- Button press → LED green + DataBroker send
- Button release → LED off + DataBroker send

**Expected logs:**
```
[Joystick] PRESSED → DataBroker + LED GREEN
✓ Sent to databroker: ButtonPressed=True
[Joystick] RELEASED → DataBroker + LED OFF
✓ Sent to databroker: ButtonPressed=False
```

**Gear (Rotary Encoder) Test:**
- First action: Clockwise (CW) → Send LAUNCH YAML, purple LED
- Next: Counter-clockwise (CCW) → Send STOP YAML, green LED
- Invalid direction → Ignore, red LED

**Expected logs:**
```
Gear signal: CW
[Gear] State=0 + CW → LAUNCH (state becomes 1)
[POST] http://192.168.0.3:47099/api/artifact yaml=container-launch.yaml status=200

Gear signal: CCW
[Gear] State=1 + CCW → STOP (state becomes -1)
[POST] http://192.168.0.3:47099/api/artifact yaml=container-stop.yaml status=200
```

## Stop

```bash
docker compose down
```

## Troubleshooting

### Arduino not recognized

```bash
# Check devices
ls -la /dev/arduino_*
arduino-cli board list

# Reapply udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Docker container cannot access Arduino

```bash
# Check devices inside container
docker exec failop-serial-bridge ls -la /dev/arduino_*

# Check permissions (rw required)
ls -la /dev/arduino_*
```

### Pullpiri connection failure

```bash
# Check Pullpiri server
curl -I http://192.168.0.3:47099/api/artifact

# Check network
ping 192.168.0.3
```

```bash
cd arduino/
./compile.sh
./install.sh
```

## Running the Bridge

```bash
cd serial/
python bridge.py
```

Or use Docker Compose (see parent folder).
