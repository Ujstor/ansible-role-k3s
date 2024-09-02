# K3s Ansible Role

Ansible role for managing rancher [k3s](https://k3s.io), lightweight, cncf-certified kubernetes distribution.
This role can be used to install simple single-node or multi-master HA clusters.
It can be used to manage multiple k3s clusters in single ansible inventory.
It's also heavily customizable for almost any purpose - you can edit pretty much any k3s setting.
It can install gvisor, additional host dependencies, load specific kernel modules, adjust k3s-related sysctl settings and so on.

Apart from [what k3s requires](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/), this role also needs systemd, so it should work on any modern distro.


### Documentation
Detailed docs are available **[here](https://k3s-docs.ujstor.com/)**

# Table of Contents
1. [Run Ansible with Docker](#2-run-ansible-with-docker)
2. [SSH Keys](#3-ssh-keys)
3. [Run Playbooks](#4-run-playbooks)
4. [Variables](#4-variables)

## 1. Run Ansible with Docker
[Back to Top](#table-of-contents)

A Docker container is the best way to manage the Ansible configuration, dependencies  and to execute playbooks.

Be sure to mount the SSH key that is responsible for host management.

```bash
docker build -t k3s-ansible .

docker run --rm -it \
  --mount type=bind,source="${HOME}"/.ssh/k3s_ansible_rsa.pem,destination=/root/.ssh/k3s_ansible_rsa.pem \
  k3s-ansible bash

source env/bin/activate
```
You are ready for executing playooks.

If the configuration is changed, rebuilding the Docker image.

## 2. SSH keys
[Back to Top](#table-of-contents)

SSH keys associated with nodes, when downloaded from RDM, are in OpenSSH format. They need to be converted into RSA format.

If the servers do not share the same SSH key, each key needs to be specified in the hosts file as the ansible_ssh_private_key_file property.
Otherwise, it should be defined in the .cfg config with private_key_file.
Also, if you SSH into servers as a non-root user, you will need to define the users for SSH in the host inventory:

```yaml
[k3s_master]
138.201.118.66 ansible_ssh_private_key_file: ~/.ssh/k3s_ansible_rsa ansible_user: administrator
```

A better approach is to have the same SSH key for the entire cluster.

```yaml
private_key_file = ~/.ssh/k3s_ansible_rsa
```

## 3. Run Playbooks
[Back to Top](#table-of-contents)

Host configuration is pulled from `hosts.ini`.

```bash
ansible-playbook k3s_playbook.yml
```

## 4. Variables
[Back to Top](#table-of-contents)

| Variable name                  | Default value                        | Description                                                                                                                          |
| ------------------------------ | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| k3s_version                    | `v1.30.3+k3s1`                       | version of k3s to install                                                                                                            |
| k3s_systemd_dir                | /etc/systemd/system                  | Directory for systemd unit file                                                                                                      |
| k3s_master                     | `false`                              | installs k3s master when true                                                                                                        |
| k3s_agent                      | `false`                              | installs k3s agent when true                                                                                                         |
| k3s_master_ip                  | first node in k3s_master_group group | ip/hostname of master node                                                                                                           |  |
| k3s_master_port                | `6443`                               | port of masterserver                                                                                                                 |
| k3s_install_mode               | `online`                             | k3s install mode - online or airgap                                                                                                  |
| k3s_flannel_backend            | `vxlan`                              | k3s flannel backend to use. Set to none to disable flannel                                                                           |
| k3s_master_disable             | `[]`                                 | array of k3s packaged components to disable (traefik,metrics-server,etc)                                                             |
| k3s_master_extra_args          | `[]`                                 | extra arguments for k3s server ([official docs](https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/)) |
| k3s_master_extra_config        | ``                                   | YAML with extra config for k3s master                                                                                                |
| k3s_agent_extra_config         | ``                                   | YAML with extra config for k3s agent                                                                                                 |
| k3s_kubelet_extra_config       | ``                                   | Additional arguments for kubelet, see docs                                                                                           |
| k3s_agent_extra_args           | `[]`                                 | extra arguments for k3s agent ([official docs](https://rancher.com/docs/k3s/latest/en/installation/install-options/agent-config/))   |
| k3s_extra_config_files         | `{}`                                 | [extra configfiles for k3s](#creating-additional-configs)                                                                            |
| k3s_bpffs                      | `false`                              | mounts /sys/fs/bpf bpffs (needed by some network stacks)                                                                             |
| k3s_external_ip                | ``                                   | specifies k3s external ip                                                                                                            |
| k3s_internal_ip                | ``                                   | specifies k3s node ip                                                                                                                |
| k3s_registries                 | ``                                   | Configures custom registries, see [official docs](https://rancher.com/docs/k3s/latest/en/installation/private-registry/) for format  |
| k3s_cronjob_prune_images       | `absent`                             | Configures cronjob that prunes unused images in containerd daily. Either `absent` or `present`                                       |
| k3s_gvisor                     | `false`                              | Installs [gvisor](https://gvisor.dev)                                                                                                |
| k3s_gvisor_version             | `20240807`                           | gvisor version to install                                                                                                            |
| k3s_gvisor_platform            | `systrap`                            | Selects [platform](https://gvisor.dev/docs/architecture_guide/platforms/) to use in gvisor                                           |
| k3s_gvisor_config              | ``                                   | Sets additional options for gvisor runsc. See notes                                                                                  |
| k3s_gvisor_create_runtimeclass | `true`                               | Automatically create gvisor RuntimeClass in kubernetes                                                                               |
| k3s_kubeconfig                 | false                                | Downloads kubeconfig to machine from which role was launched                                                                         |
| k3s_kubeconfig_server          | see below                            | specifies server for use in kubeconfig                                                                                               |
| k3s_kubeconfig_context         | k3s                                  | specifies context to use in kubeconfig                                                                                               |
| k3s_kubeconfig_target:         | ``{{ k3s_kubeconfig_context }}``     | specifies filename for downloading kubeconfig                                                                                        |
| k3s_agent_group                | k3s_node                             | specifies ansible group name for k3s nodes                                                                                           |
| k3s_master_group               | k3s_master                           | specifies ansible group name for k3s master(s)                                                                                       |
| k3s_extra_packages             | `[]`                                 | Installs additional packages if needed by workloads (ie iscsid)                                                                      |
| k3s_extra_services             | `[]`                                 | Enables additional services if needed by workloads (ie iscsid)                                                                       |
| k3s_extra_config_files         | `{}`                                 | additional config files for kubelet/kubeapi                                                                                          |
| k3s_sysctl_config              | `{}`                                 | Allows setting arbitrary sysctl settings                                                                                             |
| k3s_extra_manifests            | `{}`                                 | Allows applying kubernetes manifests                                                                                                 |
