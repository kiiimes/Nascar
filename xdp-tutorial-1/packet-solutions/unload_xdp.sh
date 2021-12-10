sudo ip link set dev tap0 xdp off
sudo ip link set dev enp2s0f1 xdp off

/* Unpinning remove prev maps */

sudo rm -rf /sys/fs/bpf/*

