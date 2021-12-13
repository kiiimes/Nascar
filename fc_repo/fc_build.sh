version='v0.25.1'

wget https://github.com/firecracker-microvm/firecracker/\
releases/download/${version}/firecracker-${version}-aarch64.tgz
wget https://github.com/firecracker-microvm/firecracker/\
releases/download/${version}/jailer-${version}-aarch64

mv firecracker-${version}-aarch64 firecracker
mv jailer-${version}-aarch64 jailer

chmod +x firecracker jailer

./firecracker --help
./jailer --help

