This blueprint demonstrates a physical multi-node SDV orchestration scenario using Eclipse Pullpiri, two NUCs, four Arduino devices, Kuksa Databroker, and Eclipse Timpani. The demo focuses on multi-node scenario contracts and type synchronization across distributed inputs, workloads, signals, and timing modes. Arduino inputs connected to the master node trigger workload lifecycle changes and CPU load control on the guest node, while LED strip workloads on the guest node visualize both application-driven periodic execution and Timpani-driven time-triggered activation. The blueprint is intended to provide a compact and reproducible example of scenario-based workload orchestration for distributed in-vehicle compute environments.

## Proposal: Multi-node Scenario Contract and Type Synchronization Blueprint using Eclipse Pullpiri

### Summary
This proposal introduces a new Eclipse SDV Blueprint that demonstrates **multi-node workload orchestration**, **scenario-based workload lifecycle control**, and **multi-node type synchronization** using Eclipse Pullpiri.

The blueprint is based on a small but physical SDV demonstration environment composed of:

- two Intel NUC devices connected over Ethernet,
- four Arduino devices connected to the NUCs,
- Eclipse Pullpiri as the vehicle workload orchestrator,
- Kuksa Databroker for signal exchange,
- and Eclipse Timpani for time-triggered workload activation.

The purpose of this blueprint is to provide a reproducible, hands-on demonstration of how a vehicle-oriented orchestrator can coordinate workloads across multiple nodes while keeping scenario intent, node roles, signal types, and workload lifecycle behavior declarative and understandable.

Unlike a purely conceptual architecture proposal, this blueprint starts from a running physical demo. It shows how scenario contracts can be used to describe what should happen across multiple nodes, and how type synchronization can ensure that signals exchanged between devices, workloads, and nodes are consistently interpreted.

### Motivation

Software-defined vehicles are increasingly composed of distributed compute nodes, external devices, vehicle data brokers, containerized workloads, and timing-sensitive runtime components.

In such environments, it is not sufficient to demonstrate only that a workload can run on one node. A practical SDV blueprint should also show:

- how a scenario is triggered from one node,
- how a workload is launched or terminated on another node,
- how signals are exchanged across nodes,
- how signal types are kept consistent,
- how timing behavior can be compared between application-driven periodic execution and scheduler-driven activation,
- and how orchestration logic can remain declarative rather than hard-coded into individual applications.

This blueprint addresses these points through a compact multi-node demo using NUCs and Arduino devices.

### Demo Topology

The demo consists of two NUCs and four Arduino devices.

<img width="522" height="694" alt="image" src="https://github.com/user-attachments/assets/1506032c-4372-47ef-816f-9601629fb8e1" />


### Physical Device Roles

#### Arduino A: Joystick

Arduino A is connected to NUC 1.

When the joystick button is pressed, it sends a signal through Kuksa Databroker to the CPU load controller running on the guest NUC.

The CPU load controller repeatedly increases and decreases the CPU load of the guest NUC.

This demonstrates:

* signal-driven control across nodes,
* remote workload behavior change,
* resource-state variation as a scenario input,
* and orchestrator-visible runtime context changes.

#### Arduino B: Rotary Encoder

Arduino B is connected to NUC 1.

When the rotary encoder is turned clockwise and the button is pressed, two scenario workloads are launched on the guest node.

When the rotary encoder is turned counterclockwise and the button is pressed, the workloads on the guest node are terminated.

This demonstrates:

* user-triggered scenario lifecycle control,
* multi-node workload launch,
* multi-node workload termination,
* scenario-level contract execution,
* and declarative workload lifecycle orchestration.

#### Arduino C: LED Strip

Arduino C is connected to NUC 2.

Whenever the workload receives a signal, the LED strip toggles between ON and OFF.

The workload controlling Arduino C wakes up from sleep every 0.5 seconds and sends a signal.

This demonstrates application-driven periodic behavior.

#### Arduino D: LED Strip

Arduino D is connected to NUC 2.

Whenever the workload receives a signal, the LED strip toggles between ON and OFF.

The workload controlling Arduino D is activated by Timpani every 0.5 seconds and sends a signal.

This demonstrates scheduler-driven periodic behavior using time-triggered activation.

### Main Blueprint Objective

The main objective of this blueprint is to demonstrate:

> A multi-node scenario contract that coordinates distributed workloads and device interactions, together with multi-node type synchronization that keeps signal interpretation consistent across Arduino devices, NUC nodes, Kuksa Databroker, Pullpiri workloads, and Timpani-triggered tasks.

The blueprint is intentionally small, physical, and reproducible. It is designed to help adopters understand how Eclipse SDV components can be combined to build a distributed scenario-oriented runtime demo.

### Key Concepts

#### 1. Multi-node Scenario Contract

A Multi-node Scenario Contract declaratively describes:

* participating nodes,
* attached devices,
* signal paths,
* workload placement,
* workload lifecycle rules,
* trigger conditions,
* expected node roles,
* timing behavior,
* and scenario-level actions.

In this demo, the scenario contract describes that:

* Arduino A on NUC 1 can trigger CPU load changes on NUC 2.
* Arduino B on NUC 1 can launch or stop two workloads on NUC 2.
* Arduino C on NUC 2 is controlled by a workload with application-level periodic wake-up.
* Arduino D on NUC 2 is controlled by a workload activated by Timpani every 0.5 seconds.

#### 2. Multi-node Type Synchronization

Multi-node Type Synchronization ensures that signal names, payload types, value ranges, units, and semantics are consistently understood across all nodes and workloads.

For example:

* joystick button events,
* rotary direction events,
* workload launch/stop commands,
* CPU load up/down commands,
* LED toggle signals,
* and periodic activation events

should have consistent type definitions across the master node, guest node, Arduino interface services, Kuksa Databroker, and workload containers.

This is important because many SDV demos fail not at orchestration itself, but at the boundaries between signal producers, brokers, consumers, and workload-specific interpretations.

#### 3. Pullpiri-based Workload Orchestration

Pullpiri is used as the orchestrator responsible for coordinating workload lifecycle and scenario execution across nodes.

In this blueprint, Pullpiri demonstrates:

* condition-based workload control,
* remote workload launch and stop,
* node role awareness,
* scenario-driven workload placement,
* and operational response to changing runtime context.

#### 4. Timpani-based Time-triggered Activation

Timpani is used to demonstrate time-triggered workload activation.

The blueprint intentionally compares two different periodic execution styles:

* Arduino C path: the workload wakes itself every 0.5 seconds.
* Arduino D path: Timpani activates the workload every 0.5 seconds.

This makes the difference between application-driven periodic execution and scheduler-driven activation visible in a simple physical demo.

### Scenario Flow

#### Scenario 1: CPU Load Control from Joystick

```text
Arduino A Joystick
      |
      v
NUC 1 input adapter
      |
      v
Kuksa Databroker signal
      |
      v
NUC 2 CPU load controller workload
      |
      v
Guest node CPU load up/down behavior
```

Expected behavior:

* Each joystick button press toggles the CPU load control command.
* The guest node CPU load controller receives the command.
* CPU load on NUC 2 repeatedly goes up and down.
* The runtime state can be observed as part of the multi-node scenario.

#### Scenario 2: Workload Launch and Termination from Rotary Encoder

```text
Arduino B Rotary Encoder
      |
      v
NUC 1 input adapter
      |
      v
Pullpiri scenario trigger
      |
      v
NUC 2 workload lifecycle control
      |
      +--> launch workload for Arduino C
      |
      +--> launch workload for Arduino D
```

Expected behavior:

* Clockwise rotation plus button press launches two workloads on the guest node.
* Counterclockwise rotation plus button press terminates the workloads.
* Pullpiri controls the workload lifecycle according to the scenario contract.

#### Scenario 3: Application-driven LED Toggle

```text
Workload on NUC 2
      |
      | wakes up every 0.5 seconds
      v
Signal to Arduino C
      |
      v
LED Strip ON/OFF toggle
```

Expected behavior:

* The workload wakes up periodically by itself.
* A signal is sent to Arduino C every 0.5 seconds.
* The LED strip toggles ON/OFF when the signal is received.

#### Scenario 4: Timpani-triggered LED Toggle

```text
Timpani scheduler
      |
      | activates workload every 0.5 seconds
      v
Workload on NUC 2
      |
      v
Signal to Arduino D
      |
      v
LED Strip ON/OFF toggle
```

Expected behavior:

* Timpani activates the workload every 0.5 seconds.
* The workload sends a signal to Arduino D.
* The LED strip toggles ON/OFF when the signal is received.

### Proposed Architecture

```text
+-------------------------------------------------------------+
| Scenario Contract                                            |
|                                                             |
| - node roles                                                 |
| - device bindings                                            |
| - signal definitions                                         |
| - workload placement                                         |
| - trigger conditions                                         |
| - lifecycle actions                                          |
| - timing mode                                                |
+-----------------------------+-------------------------------+
                              |
                              v
+-------------------------------------------------------------+
| Pullpiri Orchestration Layer                                 |
|                                                             |
| - scenario trigger handling                                  |
| - workload launch/stop                                       |
| - node coordination                                          |
| - policy-based execution                                     |
+-----------------------------+-------------------------------+
                              |
        +---------------------+---------------------+
        |                                           |
        v                                           v
+---------------------+                  +---------------------+
| NUC 1               |                  | NUC 2               |
| Master Node         |                  | Guest/Agent Node    |
|                     |                  |                     |
| Arduino A adapter   |                  | CPU load controller |
| Arduino B adapter   |                  | LED workload C      |
| Kuksa interface     |                  | LED workload D      |
| Pullpiri master     |                  | Pullpiri agent      |
|                     |                  | Timpani executor    |
+---------------------+                  +---------------------+
```

### Example Multi-node Scenario Contract

```yaml
scenario:
  id: pullpiri.multinode.arduino.demo
  name: Multi-node Arduino/NUC Orchestration Demo
  description: >
    Demonstrates multi-node scenario contract execution and type synchronization
    using Pullpiri, Kuksa Databroker, Arduino devices, and Timpani.

nodes:
  - id: nuc1
    role: master
    network: ethernet
    devices:
      - id: arduino-a
        type: joystick
        connection: usb
      - id: arduino-b
        type: rotary_encoder
        connection: usb

  - id: nuc2
    role: guest
    network: ethernet
    devices:
      - id: arduino-c
        type: led_strip
        connection: usb
      - id: arduino-d
        type: led_strip
        connection: usb

signals:
  - name: demo.joystick.button
    producer: arduino-a
    broker: kuksa
    type: boolean
    description: Joystick button event used to control guest CPU load.

  - name: demo.rotary.direction
    producer: arduino-b
    broker: kuksa
    type: enum
    values:
      - clockwise
      - counterclockwise
    description: Rotary direction used to launch or terminate guest workloads.

  - name: demo.cpu_load.command
    producer: nuc1
    consumer: nuc2.cpu-load-controller
    type: enum
    values:
      - up
      - down
      - toggle

  - name: demo.led_c.toggle
    producer: nuc2.led-workload-c
    consumer: arduino-c
    type: boolean

  - name: demo.led_d.toggle
    producer: nuc2.led-workload-d
    consumer: arduino-d
    type: boolean

workloads:
  - id: cpu-load-controller
    node: nuc2
    trigger:
      signal: demo.joystick.button
    action:
      type: toggle_cpu_load

  - id: led-workload-c
    node: nuc2
    timing:
      mode: application_sleep
      period_ms: 500
    output:
      signal: demo.led_c.toggle

  - id: led-workload-d
    node: nuc2
    timing:
      mode: timpani_time_triggered
      period_ms: 500
    output:
      signal: demo.led_d.toggle

lifecycle:
  launch:
    trigger:
      signal: demo.rotary.direction
      value: clockwise
      buttonPressed: true
    workloads:
      - led-workload-c
      - led-workload-d

  terminate:
    trigger:
      signal: demo.rotary.direction
      value: counterclockwise
      buttonPressed: true
    workloads:
      - led-workload-c
      - led-workload-d
```

### Example Type Synchronization Definition

```yaml
types:
  demo.joystick.button:
    kind: boolean
    trueMeaning: pressed
    falseMeaning: released

  demo.rotary.direction:
    kind: enum
    values:
      clockwise:
        meaning: launch_guest_workloads
      counterclockwise:
        meaning: terminate_guest_workloads

  demo.cpu_load.command:
    kind: enum
    values:
      up:
        meaning: increase_guest_cpu_load
      down:
        meaning: decrease_guest_cpu_load
      toggle:
        meaning: alternate_cpu_load_up_down

  demo.led.toggle:
    kind: boolean
    trueMeaning: toggle_requested
    falseMeaning: no_toggle
```

### What This Blueprint Demonstrates

This blueprint demonstrates:

* physical multi-node SDV orchestration,
* Pullpiri-based scenario workload launch and termination,
* Kuksa-based signal exchange between input devices and workloads,
* guest node CPU load control from a master node input,
* application-driven periodic workload execution,
* Timpani-driven time-triggered workload execution,
* Arduino-based visual feedback,
* and multi-node signal/type synchronization.

### What This Blueprint Is Not

This blueprint is not intended to be:

* an ASIL safety controller,
* a direct actuator control framework,
* a trajectory or motion control system,
* a replacement for AUTOSAR Adaptive execution management,
* a replacement for standard vehicle signal specifications,
* or a hardware-specific resource enforcement layer.

The demo is focused on QM-level operational orchestration, scenario lifecycle control, signal consistency, and timing-behavior demonstration.

### Relation to Eclipse SDV Projects

This blueprint uses or can be aligned with the following Eclipse SDV technologies:

* Eclipse Pullpiri for vehicle workload orchestration.
* Eclipse Timpani for time-triggered workload activation.
* Kuksa Databroker for signal exchange.
* Eclipse SDV Blueprints as the target project for documenting and reproducing the demo.

### Proposed Repository Structure

```text
pullpiri-multinode-scenario-blueprint/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── hardware-setup.md
│   ├── scenario-contract.md
│   ├── type-synchronization.md
│   ├── pullpiri-deployment.md
│   └── demo-guide.md
├── contracts/
│   ├── multinode-scenario.yaml
│   └── type-sync.yaml
├── arduino/
│   ├── joystick-a/
│   ├── rotary-b/
│   ├── led-strip-c/
│   └── led-strip-d/
├── workloads/
│   ├── cpu-load-controller/
│   ├── led-workload-c/
│   └── led-workload-d/
├── deployment/
│   ├── nuc1-master/
│   ├── nuc2-agent/
│   ├── pullpiri/
│   └── timpani/
├── scripts/
│   ├── setup-nuc1.sh
│   ├── setup-nuc2.sh
│   └── run-demo.sh
└── .sdv-blueprint.json
```
