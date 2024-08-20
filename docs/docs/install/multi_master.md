# Multi Master install

When your ```k3s_master``` ansible inventory group have more than 1 host, role will detect it and switch to multi-master installation.  
First node in group will be used as "bootstrap", while following will bootstrap from first node.  
Any number of nodes is ok, but it's generally recommended to have odd number of nodes for etcd eletction to work, since etcd quorum is (n/2)+1 where n is number of nodes.  

You can also switch existing, single-node sqlite master to multimaster configuration by adding more masters to existing install - be aware, however, that migration from single-node sqlite to etcd is supported only in k3s >= 1.22!

Pay attention that in default configuration all agents will be pointing only to first master, which is not really useful for HA setup. Configuring HA is out of scope for this role, so take a look at following docs:

# HA with haproxy
Using [This haproxy role](https://github.com/Oefenweb/ansible-haproxy). I run my cluster on top of L3 vpn so i can't use L2, so i just install haproxy on each node, point haproxy to all masters, and point agents to localhost haproxy. Dirty, but works. Example config:

```yaml
haproxy_listen:
  - name: stats
    description: Global statistics
    bind:
      - listen: '0.0.0.0:1936'
    mode: http
    http_request:
      - action: use-service
        param: prometheus-exporter
        cond: if { path /metrics }
    stats:
      enable: true
      uri: /
      options:
        - hide-version
        - show-node
      admin: if LOCALHOST
      refresh: 5s
      auth:
        - user: admin
          passwd: 'yoursupersecretpassword'
haproxy_frontend:
  - name: kubernetes_master_kube_api
    description: frontend with k8s api masters
    bind:
      - listen: "127.0.0.1:16443"
    mode: tcp
    default_backend: k8s-de1-kube-api
haproxy_backend:
  - name: k8s-de1-kube-api
    description: backend with all kubernetes masters
    mode: tcp
    balance: roundrobin
    option:
      - httpchk GET /readyz
    http_check: expect status 401
    default_server_params:
      - inter 1000
      - rise 2
      - fall 2
    server:
      - name: k8s-de1-master-1
        listen: "master-1:6443"
        param:
          - check
          - check-ssl
          - verify none
      - name: k8s-de1-master-2
        listen: "master-2:6443"
        param:
          - check
          - check-ssl
          - verify none
      - name: k8s-de1-master-3
        listen: "master-3:6443"
        param:
          - check
          - check-ssl
          - verify none
```

That will start haproxy listening on 127.0.0.1:16443 for connections to k8s masters. You can then redefine master IP and port for agents with
```yaml
k3s_master_ip: 127.0.0.1
k3s_master_port: 16443
```

And now your connections are balanced between masters and protected in case of one or two masters will go down. One downside of that config is that it checks for reply 401 on /readyz endpoint, because since certain version of k8s (1.19 if i recall correctly) this endpoint requires authorization. So you have 2 options here:

  * Continue to rely on 401 check (not a good solution, since we're just checking for http up status)
  * Add ```anonymous-auth=true``` to apiserver arguments: 
      ```yaml
        k3s_master_extra_config:
          kube-apiserver-arg:
          - "anonymous-auth=true"
      ```
    This will open /readyz, /healthz, /livez and /version endpoints to anonymous auth, and potentially expose version info. If that is concerning you, it's possible to patch system:public-info-viewer role to keep only /readyz, /healthz and /livez endpoint open:
    ```
    kubectl patch clusterrole system:public-info-viewer --type=json -p='[{"op": "replace", "path": "/rules/0/nonResourceURLs", "value":["/healthz","/livez","/readyz"]}]'
    ```
  
This proxy also works with initial agent join, so it's better to setup haproxy before installing k3s and then switching to HA config.
It will also expose prometheus metrics on 0.0.0.0:1936/metrics - pay attention that this part (unlike webui) won't be protected by user and password, so adjust your firewall accordingly if needed!

Of course you can use whatever you want - external cloud LB, nginx, anything, all it needs is TCP protocol support (because in this case we don't want to manage SSL on loadbalancer side). But haproxy provides you with prometheus metrics, have nice webui for monitoring and management, and i'm just familiar with it.

# HA with VRRP (keepalived)
You can use [this keepalived role](https://github.com/Oefenweb/ansible-keepalived) if you have L2 networking available and can use VRRP for failover IP. In that case, you might need to add tls-san option in k3s_master_extra_config with your floating ip.
For keepalived to work, following conditions should be met:
  1) L2 networking must be available. Sadly, this is not a common case with cloud providers and most VPNs.
  2) Virtual IP must be in same subnet as interfaces on top of which they are used

Sample keepalived configuration on master-1, assuming we use network 10.91.91.0/24 on vpn0 interface:
```yaml
keepalived_instances:
  vpn:
    interface: vpn0
    state: MASTER
    virtual_router_id: 51 #if you have multiple VRRP setups in same network this should be unique
    priority: 255 #node usually owning IP should always have priority set to 255
    authentication_password: "somepassword" #can be omitted, but always good to use
    vips:
      - "10.91.91.50 dev vpn0 label vpn0:0"
```
for backing masters:
```yaml
keepalived_instances:
  vpn:
    interface: vpn0
    state: BACKUP
    virtual_router_id: 51
    priority: 254 #use lower priority for each node
    authentication_password: "somepassword"
    vips:
      - "10.91.91.50 dev vpn0 label vpn0:0"
```
And in k3s configuration:
```yaml
k3s_master_extra_config:
  tls-san: 10.91.91.50
```

If everything is configured correctly, you should see 10.91.91.50 on vpn0:0 interface on master-1 node. Try stopping keepalived on master-1 and see how IP disappears from master-1 and appears on master-2.  
From now it's your choice how you want to configure HA - point agents to that floating IP, or install load-balancer on each master node and distribute requests between them.
