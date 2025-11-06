# netem
Network emulator to affect only external traffic (exclude 192.168.0.0/16)

## Installation
Download it
```
wget https://github.com/joaomdalmolin/netem/releases/download/v0.0.1/netem.sh
# OR
curl -O https://github.com/joaomdalmolin/netem/releases/download/v0.0.1/netem.sh
```
Download and allow it to be executed
```
chmod +x netem.sh
```

## Usage:
```
sudo ./netem.sh <add|del> <interface> [latency] [jitter] [bandwidth] [packet_loss]
```

## Examples:
```
sudo ./netem.sh add eth0 100ms 30ms 10mbit 2%
# only change latency
sudo ./netem.sh add eth0 200ms
sudo ./netem.sh del eth0
```

## Description:
   - "add" applies network emulation (sets only specified params).
   - "del" removes tc and iptables configurations.
   - \<interface> interface name 
   - \<latency> latency with unit (e.g. 100ms)
   - \<jitter> jitter with unit (e.g. 50ms)
   - \<bandwidth> bandwidth with unit (e.g. 10mbit)
   - \<packet_loss> packet loss with unit (e.g. 5%)
