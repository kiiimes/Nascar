#sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern_03.o --progsec xdp_redirect_map -F
#sudo ./xdp_loader -d eth0 -S --filename xdp_prog_kern_03.o --progsec xdp_pass -F
#sudo ./xdp_loader -d eth0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
#sudo ./xdp_prog_user -d eth0
#sudo ./xdp_prog_user -d tap0
#sudo ./xdp_prog_user -d tap0 -r eth0 --src-mac $1 --dest-mac $2
mount -t bpf bpf /sys/fs/bpf
sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
#sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
#sudo ./xdp_prog_user -d tap0
sudo ./xdp_prog_user -d tap0
