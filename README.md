### Description
Ansible role for managing rancher [k3s](https://k3s.io), lightweight, cncf-certified kubernetes distribution.  
I use it for my personal kubernetes installs/test labs running on bunch of cheap KVM VPSes, some raspberries, some cloud VMs and so on.  
It's tailored for my needs (ie gvisor and etc), but it's still very generic and can be used anywhere, and my customizations are disabled via variables by default.

 <!-- TOC -->

- [Description](#description)
- [Docs:](#docs)
- [Requirements](#requirements)
- [Variables](#variables)
- [Tests](#tests)
- [Other ansible roles to check out](#other-ansible-roles-to-check-out)

<!-- /TOC -->

### Docs: 

Detailed docs are available [here](https://rlex.github.io/ansible-role-k3s/)

### Requirements
Apart from [what k3s requires](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/), this role also needs systemd, so it should work on any modern distro.  

### Variables

| Variable name                  | Default value                    | Description                                                                                                                          |
| ------------------------------ | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| k3s_version                    | `v1.28.4+k3s2`                   | version of k3s to install                                                                                                            |
| k3s_master                     | `false`                          | installs k3s master when true                                                                                                        |
| k3s_agent                      | `false`                          | installs k3s agent when true                                                                                                         |
| k3s_master_ip                  | see below                        | ip of master node                                                                                                                    |
| k3s_master_port                | `6443`                           | port of masterserver                                                                                                                 |
| k3s_flannel_backend            | `vxlan`                          | k3s flannel backend to use. Set to none to disable flannel                                                                           |
| k3s_server_disable             | `[]`                             | array of k3s packaged components to disable (traefik,metrics-server,etc)                                                             |
| k3s_master_extra_args          | `[]`                             | extra arguments for k3s server ([official docs](https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/)) |
| k3s_master_additional_config   | ``                               | YAML with extra config for k3s master                                                                                                |
| k3s_agent_additional_config    | ``                               | YAML with extra config for k3s agent                                                                                                 |
| k3s_kubelet_additional_config  | ``                               | Additional arguments for kubelet, see docs                                                                                           |
| k3s_agent_extra_args           | `[]`                             | extra arguments for k3s agent ([official docs](https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config/))   |
| k3s_additional_config_files    | `{}`                             | [extra configfiles for k3s](#creating-additional-configs)                                                                            |
| k3s_bpffs                      | `false`                          | mounts /sys/fs/bpf bpffs (needed by some network stacks)                                                                             |
| k3s_external_ip                | ``                               | specifies k3s external ip                                                                                                            |
| k3s_internal_ip                | ``                               | specifies k3s node ip                                                                                                                |
| k3s_registries                 | ``                               | Configures custom registries, see [official docs](https://rancher.com/docs/k3s/latest/en/installation/private-registry/) for format  |
| k3s_cronjob_prune_images       | `absent`                         | Configures cronjob that prunes unused images in containerd daily. Either `absent` or `present`                                       |
| k3s_gvisor                     | `false`                          | Installs [gvisor](https://gvisor.dev)                                                                                                |
| k3s_gvisor_platform            | `systrap`                        | Selects [platform](https://gvisor.dev/docs/architecture_guide/platforms/) to use in gvisor                                           |
| k3s_gvisor_config              | ``                               | Sets additional options for gvisor runsc. See notes                                                                                  |
| k3s_gvisor_create_runtimeclass | `true`                           | Automatically create gvisor RuntimeClass in kubernetes                                                                               |
| k3s_kubeconfig                 | false                            | Downloads kubeconfig to machine from which role was launched                                                                         |
| k3s_kubeconfig_server          | see below                        | specifies server for use in kubeconfig                                                                                               |
| k3s_kubeconfig_context         | k3s                              | specifies context to use in kubeconfig                                                                                               |
| k3s_kubeconfig_target:         | ``{{ k3s_kubeconfig_context }}`` | specifies filename for downloading kubeconfig                                                                                        |
| k3s_agent_group                | k3s_node                         | specifies ansible group name for k3s nodes                                                                                           |
| k3s_master_group               | k3s_master                       | specifies ansible group name for k3s master(s)                                                                                       |
| k3s_additional_packages        | `[]`                             | Installs additional packages if needed by workloads (ie iscsid)                                                                      |
| k3s_additional_services        | `[]`                             | Enables additional services if needed by workloads (ie iscsid)                                                                       |
| k3s_sysctl_config              | `{}`                             | Allows setting arbitrary sysctl settings                                                                                             |
| k3s_additional_manifests       | `{}`                             | Allows applying kubernetes manifests                                                                                                 |

### Tests
This role is continiously tested via ansible-molecule with github actions in on Ubuntu 22.04 and Rocky Linux 8 in different scenarios, including:
  * single-node install
  * single-node install with heavily customized config
  * single-node airgapped install
  * cluster install (3 masters, 1 node)

### Other ansible roles to check out

If you got interested in that role, you might want to check out others that go nicely with my k3s one:

[haproxy by Oafenweb](https://github.com/Oefenweb/ansible-haproxy) - used in example with haproxy
[keepalived by Oafenweb](https://github.com/Oefenweb/ansible-keepalived) - used in example with keepalived
[zot registy by me](https://github.com/rlex/ansible-role-zot) - for light on resources (but also very powerful) OCI container registry
