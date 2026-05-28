# Fail-Operation Guest - KUKSA Subscriber

A KUKSA databroker subscriber running on NUC Guest.
Receives button events and executes workload containers.

## Configuration File

Container settings are managed through the `.env` file.

### .env File Format

```bash
# Container image to use for workload
CONTAINER_IMAGE=stress-ng

# Container name (fixed, will not change on each run)
CONTAINER_NAME=failop-workload

# Stress-ng CPU cores
STRESS_CPU=2

# Stress-ng timeout
STRESS_TIMEOUT=30s
```

### Changing Configuration

1. Modify the `.env` file
2. Restart container (automatically loads new settings)

```bash
# Edit .env file
vi /home/lge/work/sdv-blueprint/fail-operation/nuc_base/nuc_guest/kuksa-bridge/.env

# Restart (automatically applies new settings)
docker restart failop-kuksa-bridge-guest
```

## Build

```bash
cd /home/lge/work/sdv-blueprint/fail-operation/nuc_base/nuc_guest/kuksa-bridge
docker build -t failop-kuksa-bridge-guest:latest .
```

## Running

```bash
docker run --rm -d \
  --name failop-kuksa-bridge-guest \
  --network host \
  -v /home/lge/work/sdv-blueprint/fail-operation/nuc_base/nuc_guest/kuksa-bridge/.env:/app/.env \
  -e PYTHONUNBUFFERED=1 \
  failop-kuksa-bridge-guest:latest
```

## Check Logs

```bash
# Real-time log monitoring
docker logs failop-kuksa-bridge-guest -f

# Recent logs
docker logs failop-kuksa-bridge-guest --tail=20
```

## Operation Method

1. **KUKSA Databroker Connection**
   - Port: `55556` (fail-operation databroker)
   - Signal: `Vehicle.Cabin.FailOperation.ButtonPressed`

2. **Button Event Handling**
   - Button PRESSED → Execute workload container
   - Button RELEASED → No action

3. **Container Execution**
   - Delete existing container with same name, then run new one
   - Load settings from `.env` file
   - Run with `podman run`

## Notes

- Container name is fixed to the name configured in `.env`
- If a container with the same name is running, it is automatically deleted and restarted
- The `.env` file can be modified at runtime (applied on restart or next button event)
