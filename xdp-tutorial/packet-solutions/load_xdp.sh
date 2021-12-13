sudo mount -t bpf bpf /sys/fs/bpf
sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
sudo ./xdp_prog_user --dev tap0
sudo ./xdp_loader -d eth0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
sudo ./xdp_prog_user --dev eth0
