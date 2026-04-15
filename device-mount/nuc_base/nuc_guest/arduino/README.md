# Demo with NUC

The following instructions are based on a CentOS Stream environment with x86_64 architecture.

## Prerequisites

### Buzzer Identification

The devices look identical, but the buzzer with a white sticker is the active buzzer, while the one with only a black device (no sticker) is the passive buzzer.

### Device Paths

Since the device path `/dev/ttyACMx` may change each time a device is connected, it needs to be fixed using udev rules.

The `99-arduino-buzzer.rules` file is structured as follows:

```
# Active buzzer Arduino
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{serial}=="3CDC75F04E2C", SYMLINK+="arduino_active"

# Passive buzzer Arduino
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{serial}=="3CDC75F03F08", SYMLINK+="arduino_passive"
```

Here, `2341` is Arduino's vendor code, and each device's serial number can be found using the following command:

```
udevadm info -a -n /dev/ttyACM0 | grep '{serial}' -m 1
```

The number in `ttyACM0` increments each time an Arduino device is connected. Use the `arduino-cli board list` command to identify which path the device is attached to.

Finally, execute the following commands to apply the rules and verify creation:

```
sudo cp 99-arduino-buzzer.rules /etc/udev/rules.d/99-arduino-buzzer.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
ls -al /dev/arduino_*
```

## Compilation

To compile, execute `compile.sh`. Note that the `.ino` filename and folder name must match for compilation to succeed.

```sh
arduino-cli compile --fqbn arduino:renesas_uno:unor4wifi ardn_buzzer_active
arduino-cli compile --fqbn arduino:renesas_uno:unor4wifi ardn_buzzer_passive
```

Upon successful compilation, you should see output similar to:
```
Sketch uses 52224 bytes (19%) of program storage space. Maximum is 262144 bytes.
Global variables use 6740 bytes (20%) of dynamic memory, leaving 26028 bytes for local variables. Maximum is 32768 bytes.
```

## Installation

To install, execute `install.sh`. However, there's an important caveat:

```sh
arduino-cli upload -p /dev/ttyACM0 --fqbn arduino:renesas_uno:unor4wifi ardn_buzzer_active
arduino-cli upload -p /dev/ttyACM1 --fqbn arduino:renesas_uno:unor4wifi ardn_buzzer_passive
```

As shown in the script above, you must use the original device path (e.g., `/dev/ttyACMx`) instead of `/dev/arduino_*` for the upload to succeed.
Therefore, use `ls -al /dev/arduino_*` to correctly match the folder with the actual device path.

```
# ls -al /dev/arduino_*
lrwxrwxrwx 1 root root 7 Mar 24 15:17 /dev/arduino_active -> ttyACM0
lrwxrwxrwx 1 root root 7 Mar 24 15:17 /dev/arduino_passive -> ttyACM1
```

In this example, the active buzzer is connected to `/dev/ttyACM0`, so the first entry in the installation script should reference `ACM0`.

