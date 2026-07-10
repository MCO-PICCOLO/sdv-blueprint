# Preflight Scripts (Multi-node)

- `prepare_master.sh`: master 준비 (이미지/아두이노)
- `prepare_guest.sh`: guest 준비 (이미지/아두이노/모니터링 체크)

## Usage

```bash
cd /home/lge/work/demo/sdv-blueprint/resource-isolation/multi_node/test_script/preflight
chmod +x prepare_master.sh prepare_guest.sh

# master 에서
./prepare_master.sh

# guest 에서
./prepare_guest.sh
```

## Options (env)

- `SKIP_ARDUINO=1` : 아두이노 단계 건너뜀
- `SKIP_IMAGE=1` : 이미지 단계 건너뜀
