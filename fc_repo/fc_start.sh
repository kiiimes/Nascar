sudo ./firectl/firectl --firecracker-binary=./firecracker --kernel=v4.14/vmlinux.bin --tap-device=tap0/aa:fc:00:00:00:01 --kernel-opts="init=/bin/systemd console=ttyS0 reboot=k panic=1 pci=off" --root-drive=ubuntu.ext4 --ncpus=8 --memory=2048

