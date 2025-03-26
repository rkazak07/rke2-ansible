# RKE2 Debian/Ubuntu ansible Playbook

 Bu doküman, Rke2 yapısının Ansible ile Centos/Rhel/Oel, Debian 12 ve Ubuntu sistemlerinde nasıl kurulup yönetileceğini anlatır.

### 🚀 Desteklenen İşletim Sistemleri
* ✅ Debian 12
* ✅ Ubuntu (22.04, 24.04)

## 🛠 Değişkenlerin Düzenlenmesi

### 📌 Inventories Dosyası (inventories/hosts.ini)
Sunucularınızı ve IP adreslerini aşağıdaki gibi belirtebilirsiniz:

```
[server]
master1 ansible_host=192.168.1.101
master2 ansible_host=192.168.1.102
master3 ansible_host=192.168.1.103

[agent]
worker1 ansible_host=192.168.1.201
worker2 ansible_host=192.168.1.202

[all:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3

```

### 📌 Genel Ayarlar (inventories/group_vars/all.yml)
Rke2 ve sunucuların genel ayarları buradan yönetilebilir:
Rke2 versiyonu sunucu paketleri, ntp ayarları, sysctl ayarları, /etc/hosts, iptables ayarları buradan düzenlenmektedir.

```
rke2_version: "v1.32.3-rc1+rke2r1"    

common_sysctl_params:
  net.ipv4.ip_forward: 1
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.bridge.bridge-nf-call-arptables: 1
  net.ipv4.ip_local_reserved_ports: 30000-32767
  kernel.keys.root_maxbytes: 25000000
  kernel.keys.root_maxkeys: 1000000
  kernel.panic: 10
  kernel.panic_on_oops: 1
  vm.overcommit_memory: 1
  vm.panic_on_oom: 0
  fs.inotify.max_queued_events: 16384
  fs.inotify.max_user_instances: 128
  fs.inotify.max_user_watches: 123047

# Cluster için ihtiyaç duyduğumuz paketleri kuruyoruz.
common_packages:
  - iptables
  - apt-transport-https
  - ca-certificates
  - curl
  - wget

# etc/hosts ayarlamalarımız gerçekleştiriyoruz.
hosts_entries:
  - ip: "192.168.117.133"
    fqdn: "master01.domain.com"
    short: "master01"
  - ip: "192.168.117.134"
    fqdn: "master02.domain.com"
    short: "master02"
  - ip: "192.168.117.135"
    fqdn: "master03.domain.com"
    short: "master03"
  - ip: "192.168.117.200" # LB ip adress address
    fqdn: "master-lb.domain.com"
    short: "master-lb"

ntp_servers:
  - "0.tr.pool.ntp.org"
  - "1.tr.pool.ntp.org"


iptables_install: true
iptables_rules_v4:
  - "-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT"
  - "-A INPUT -p tcp -m tcp --dport 443 -j ACCEPT"
  - "-A INPUT -p tcp -m tcp --dport 8200 -j ACCEPT"
  - "-A INPUT -s 192.168.117.133/32 -p tcp -m tcp -j ACCEPT"
  - "-A INPUT -s 192.168.117.134/32 -p tcp -m tcp -j ACCEPT"
  - "-A INPUT -s 192.168.117.135/32 -p tcp -m tcp -j ACCEPT"
  - "-A INPUT -s 192.168.117.133/32 -p udp -m udp -j ACCEPT"
  - "-A INPUT -s 192.168.117.134/32 -p udp -m udp -j ACCEPT"
  - "-A INPUT -s 192.168.117.135/32 -p udp -m udp -j ACCEPT"

```
* rancher_ui_enabled: false → Rancher ui kurulumu için true yapınız
* rancher_helm_chart_version: "2.8.4"  →  Rancher Helm chart versiyonu
* rancher_hostname: "rancher.domain.com" → rancher arayüzüne erişim sırasında kullanılacak olan dns adresini belirtiniz.

### 📌 Rke2 Servers Ayarları (inventories/group_vars/server.yml)
Bu config'de Rke2 master sunucuları için ihtiyaç duyulan parametreler düzenlenmektedir.

```
rke2_config_master:
  server: https://my-kubernetes-domain.com:9345 # LB 
  cni: "calico"
  #disable:
  #  - "rke2-ingress-nginx"
  tls-san:
    - "master1"
    - "master2"
    - "master3"
  node-taint: 
  - node-role.kubernetes.io/control-plane=true:NoSchedule
  - node-role.kubernetes.io/etcd=:NoExecute
  write-kubeconfig-mode: "0644"
  #advertise-address: 192.168.117.200
  cluster-cidr: "10.42.0.0/16"
  service-cidr: "10.43.0.0/16"
  cluster-domain: "cluster.local"
  cluster-dns: "10.43.0.10"
  etcd-disable-snapshot: false
  etcd-snapshot-schedule-cron: "0 */12 * * *"
  etcd-snapshot-retention: 7
  etcd-arg: "--quota-backend-bytes 2048000000"

master_data_path: "/data/rke2-master"

```

### 📌 Rke2 Agents Ayarları (inventories/group_vars/agent.yml)

```
rke2_config_worker:
  server: "https://my-kubernetes-domain.com:9345"
  cni: "calico"

worker_data_path: /data/rke2-worker
```

## 🚀 Ansible Playbook Çalıştırma

group_vars ve inventories düzenlemerini sisteminize göre sağladıktan sonra playbook'u çalıştırınız. Playbook çalıştırılmadan önce sunucularda *curl*, *sshpass*, *sudo* yüklü olması gerekmektedir.

```
ansible-playbook -i inventories/hosts.ini site.yml
```

DEBUG Modu için

```
ansible-playbook -i inventories/hosts.ini site.yml -vvv
```