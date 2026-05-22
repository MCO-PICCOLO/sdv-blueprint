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
