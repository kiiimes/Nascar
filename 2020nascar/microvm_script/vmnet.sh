#! /bin/bash
ip addr add 172.16.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 172.16.0.1 dev eth0
echo nameserver 8.8.8.8 >> /etc/resolv.conf
ethtool -K eth0 tso off
