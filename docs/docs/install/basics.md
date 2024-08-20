This role discovers installation mode from your ansible inventory. 
For working with your inventory, it operates on two basic variables,  ```k3s_master_group``` and ```k3s_agent_group```, which are set to ```k3s_master``` and ```k3s_agent``` by default.

Following is an example of single master and 2 agents:
```ini
[k3s_master]
kube-master-1.example.org

[k3s_agent]
kube-node-1.example.org
kube-node-2.example.org
```

For group with master, k3s_master in that example, you should enable master installation with ```k3s_master``` variable:
```yaml
k3s_master: true
```

Accordingly, for agents, use ```k3s_agent``` variable:
```yaml
k3s_agent: true
```

For selecting master server to connect, you can use ```k3s_master_ip``` variable.
By default it will be set to first ansible_host in ansible group specified in ```k3s_master_group``` variable.  
Of course, you can always redefine it manually.

```yaml
- name: k3s multi node - master
  hosts: k3s_master
  become: yes
  become_user: root
  gather_facts: False
  roles:
    - role: k3s
  vars:
    k3s_master: true
    k3s_kubeconfig: true
    k3s_master_extra_args:
      - "--token alskdfjasljkfdlasjflakjsdflkj"

- name: k3s multi node - agent
  hosts: k3s_agent
  become: yes
  become_user: root
  gather_facts: False
  roles:
    - role: k3s
  vars:
    k3s_agent: true
    k3s_agent_extra_args:
      - "--server https://kube-master-1.example.org:6443"
      - "--token alskdfjasljkfdlasjflakjsdflkj"
```
