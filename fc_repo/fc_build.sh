version='v0.25.1'

wget https://github.com/firecracker-microvm/firecracker/\
releases/download/${version}/firecracker-${version}-aarch64.tgz

mv firecracker-${version}-aarch64 firecracker

chmod +x firecracker

./firecracker --help
