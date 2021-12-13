HOST_IFACE=eth0
TAP_DEV=tap0
iptables -F # flush all chains
iptables -t nat -F
iptables -t mangle -F
iptables -X # delete all chains

iptables -t nat -A POSTROUTING -o $HOST_IFACE -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $TAP_DEV -o $HOST_IFACE -j ACCEPT

