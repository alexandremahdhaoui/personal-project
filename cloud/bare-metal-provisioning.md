# Bare metal provisioning

## Prologue 

Provisioning monitoring & operating should be as simple et reproducible as possible

Any bare metal machine could be randomly wiped-out and & recreated on-demand.


## Ideas

- Bare metal provisioning can be orchestrated
  - Machine can fail, wiped-out, recreated...
  - Any machine can boot up & register itself to the orchestrator
  - Orchestrator evaluates available hardware & resources of the registered machines.
  - Orchestrator then decides at its better convenience how to use these resources.
- Bare metal authn: using USB key with key/certificate to authn a bare-metal machine.

- [baremetal-operator](https://github.com/metal3-io/baremetal-operator/tree/main)
- [Bare metal links & resources](https://github.com/alexellis/awesome-baremetal)

## TODOs

- [ ] PXE server on the bare metal local network
  - Requirements: storage for the images. A k8s cluster to run the PXE server.
