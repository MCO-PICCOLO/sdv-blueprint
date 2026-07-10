# Multi-node Resource Isolation Test

Scripts to run and tear down a pullpiri + TIMPANI based resource-isolation scenario across master and guest nodes.

## Structure

```
test_script/
├── config.env                        # settings (edit here only)
├── run_resource_isolation_flow.sh    # start
├── stop_resource_isolation_flow.sh   # stop
├── preflight/                        # one-time environment setup (image build / Arduino)
│   ├── prepare_master.sh
│   └── prepare_guest.sh
├── lib/utils.sh                      # shared functions
└── pullpiri/                         # pullpiri install/uninstall scripts, node config
```

## Prerequisites

- The same `sdv-blueprint` path exists on both master and guest
- master: `docker`, `arduino-cli`, `podman`
- guest: `podman`, `arduino-cli`
- Local runner host: `ssh`, `sshpass` (when using password authentication)

## 1. Configure

Edit only the **USER SETTINGS** section at the top of [config.env](config.env).

- Node connection info: `MASTER_HOST/PORT/USER/PASS`, `GUEST_HOST/PORT/USER/PASS`
- `GUEST_NODE_IP`: guest internal-network IP (auto-detected if empty)
- `MASTER_BASE_DIR`, `GUEST_BASE_DIR`: `sdv-blueprint` path on each node

## 2. Preflight (one-time)

Run directly on each node.

```bash
# on the master node
./preflight/prepare_master.sh

# on the guest node
./preflight/prepare_guest.sh
```

## 3. Run

```bash
./run_resource_isolation_flow.sh
```

At Step 6, operate the Arduino and send the YAML. The flow detects the databroker log and automatically proceeds to the next step.

## 4. Stop

```bash
./stop_resource_isolation_flow.sh
```

## Notes

- Detailed values such as node paths and image versions can be overridden in the **ADVANCED SETTINGS** section of `config.env`.
- Scripts work regardless of the current working directory (they resolve paths relative to their own location).
