
sudo ip link set dev tap0 xdp off
sudo ip link set dev eth0 xdp off 

/* Unpinning remove prev maps */

sudo rm -rf /sys/fs/bpf/*

sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern.o --progsec xdp_redirect_map -F
sudo ./xdp_loader -d eth0 -S --filename xdp_prog_kern.o --progsec xdp_redirect_map -F
