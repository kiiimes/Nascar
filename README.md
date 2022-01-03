# Nascar 관련 내용 및 실험 정리
## Nascar 과제 내용
	* microVM은 tap0로 통신을 하고 eth0와 virtio로 구성이 되어 있음. 라즈베리파이에서 tap0와 eth0의 통신 과정에 ip forwarding 오버헤드가 높음. 그래서, microVM에서 tap0를 거치지 않고 바로 우분투 서버로 패킷을 전송할 수 있도록 bypass를 하려고 함. 
		* IP forwarding은 반복적인 routing table lookup과 netfilter 연산으로 오버헤드가 높음
		* 동일한 traffic (같은 src/dst 주소)에 대한 반복적인 연산은 비효율적
		* 오버헤드를 줄여 firecracker의 네트워크 성능을 높이는 것이 목표 
	* IP forwarding 오버헤드를 줄이기 위해 XDP라는 네트워크 스택을 우회하여 패킷을 보낼 수 있는 오픈 소스를 사용하여 바로 microVM에서 우분투로 패킷 전송을 하려 함.
		* xdp_router 코드에서 bpf_fbi_lookup을 통해 얻은 정보로 패킷의 spac과 dmac을 수정하여 bpf_redirect_map을 호출하는 과정을 xdp에서 알아서 해줌 ( 이 과정에서 라우팅 테이블 수정 없었음 ) 
		* 전체적인 과정을 그림으로 나타내면 아래의 그림과 같음
[image:99BF296F-5545-42A9-B87A-BF1B209C40BF-2695-0000418581388309/202E6CE8-80C2-402B-9C95-5459C9CA8FBE.png]
	* 실험은 64B TCP packet을 기준으로 진행
		* 차량용으로 firecracker를 이용하려는 것이기 때문에 메시지 크기가 작은 경우가 주 타겟

## 실험 환경 세팅
* 10번 서버(10.0.0.200) 디렉토리 -> /home/fire/eskim/firecracker/fc_repo
* CPU model : E5-2650 v3, 10 cores CPU, 10GbE network interface, 256GB memory
* 버전 정리
	* 리눅스 커널 : 5.13.0-051300-generic
	* 우분투 버전 : 21.04
	* firecracker 버전 : 0.25.1
	* firectl 버전 : 0.1.0
	* kata 버전 : 1.11.4
	* vmlinux 버전 : 4.14.174+
	* netperf 버전 : 2.6.0
* firecracker 설치 및 빌드 (버전, 회사?에 따라 맞춰 설치)
	* fc_build.sh 참고
```
#raspberry - amd
wget https://github.com/firecracker-microvm/firecracker/\
releases/download/${version}/firecracker-${version}-aarch64.tgz

#server - arm
wget https://github.com/firecracker-microvm/firecracker/\
releases/download/${version}/firecracker-${version}-x86_64.tgz
```
		* firecracker, jailer 실행파일 생성됨
	* firectl 설치 및 빌드(firecracker microvm을 실행할 수 있는 커맨드 라인 툴)
```
wget https://golang.org/dl/go1.14.12.linux-arm64.tar.gz
tar xzvf go1.14.12.linux-arm64.tar.gz
git clone https://github.com/firecracker-microvm/firectl.git
cd firectl/
../go/bin/go build -x
./firectl --help
wget https://s3.amazonaws.com/spec.ccfc.min/img/aarch64 or x86_64/ubuntu_with_ssh/kernel/vmlinux.bin
wget https://s3.amazonaws.com/spec.ccfc.min/img/aarch64 or x86_64/ubuntu_with_ssh/fsfiles/xenial.rootfs.ext4
```
		* 각 커널 이미지 파일 및 우분투 이미지는 여러가지가 있으니 용도에 따라 찾아서 설치
		* 사용 커널 이미지 : v4.14/vmlinux.bin
		* 사용 우분투 이미지 :  xenial.rootfs.ext4 -> vnstat, pidstat, mpstat, vim, netperf 등의 툴 설치 필요
	* 네트워크 인터페이스에 tap0 생성
		* sh host_net.sh 

## firecracker 실험 방법 - 10번 서버 기준
* 먼저, netperf 실험을 위해 받는 쪽 서버(1번 서버 [10.0.0.25] )에 netserver 실행 및 라우팅 설정 
	`netserver -p 1` -> netserver 실행
	* `sudo route add -net 172.16.0.0 netmask 255.255.0.0 gw 10.0.0.200`
		* —gw : 이 ip로 들어오는 패킷들을 
		* —net : 이 ip로 보내라
* firecracker 실행
	* sh fc_start.sh 실행
		* `sudo ./firectl/firectl --firecracker-binary=./firecracker --kernel=v4.14/vmlinux.bin --tap-device=tap0/aa:fc:00:00:00:01 --kernel-opts="init=/bin/systemd console=ttyS0 reboot=k panic=1 pci=off" --root-drive=xenial.rootfs.ext4 --ncpus=8 --memory=2048`
		* firecracker 실행 옵션
			* ncpus = 8 (8 cores)
			* memory = 2048 (2GB memory)
			* kernel = kernel 이미지
			* root-drive = 우분투 이미지
	* 실행 ID, PW
		* ID : root / PW : root
	* [참고] [ 167.842087] EXT4-fs error (device vda): ext4_lookup:1604: inode #132314: comm systemd-journal: deleted inode referenced: 133533 이러한 오류가 발생하면 아래의 커맨드 사용
	`sudo setfacl -m u:${USER}:rw /dev/kvm`
* microvm 내부에서 tap0 통신 설정
	* sh vmnet.sh 실행
	* 혹은 firecracker 실행시 kernel-opts에 다음과 같은 옵션을 주면 vmnet.sh 실행을 하지 않아도 됨
		* `sudo ./firectl/firectl --firecracker-binary=./firecracker --kernel=v4.14/vmlinux.bin --tap-device=tap0/aa:fc:00:00:00:01 --kernel-opts="init=console=ttyS0 reboot=k panic=1 pci=off ip=172.16.0.42::172.16.0.1:255.255.255.0::eth0:off" --root-drive= xenial.rootfs.ext4 --ncpus=8 --memory=2048`
* [참고] microvm 내부에서 apt-get 이 안된다면 다음 스크립트를 실행하면 됨 
	* sh reset_ net.sh
		* HOST_IFACE=eth0 에서 외부로 패킷 전송하는 NIC으로 설정하면 됨
		* 사용 후 다시 HOST_IFACE를 Microvm 인터페이스로 바꿔주면 됨
* 실험 방법 
	* 64B TCP packet을 1번 서버(netserver)로 전송
	* 55초씩 3번 실험 진행
* microvm 내부에서 netperf 실행
	* sh  run_host.sh
		* 4개의 netperf thread를 실행하고, 64B or 16KB로 실험 진행 
			* 8개 core에 4개 thread 실행한 이유는 4개 core 딱맞춰서 할당하면 각 thread 간 네트워크 성능 편차가 심해져서 다른 인터럽트 처리를 수행할 여유 CPU가 있어야함 
		* vnstat으로 microvm 내부의 네트워크 인터페이스에 대해 네트워크 성능 측정 
		* microvm 외부에서 pidstat, vnstat, mpstat을 이용하여 네트워크 및 CPU 사용량 측정 
* microvm 외부에서 성능 측정
	* microvm 내부의 run_host.sh에서 다음 스크립트를 실행함
		* /home/fire/eskim/firecracker/2020nascar/test_f/eskim/run_host.sh
			* cpu, network 성능 측정 및 perf data 생성 
			* flame graph 생성
* firecracker 종료
	* microvm 내부에서 reboot 실행 -> vm 종료됨

## xdp 적용 firecracker 실험 방법 
* 10번 서버 디렉토리 -> /home/fire/eskim/firecracker/xdp-tutorial-1/packet-solutions
* xdp 설치 및 빌드 [새로 설치 및 빌드할 경우]
	* https://github.com/xdp-project/xdp-tutorial
* xdp 적용 방법
	* sh load_xdp.sh
```
mount -t bpf bpf /sys/fs/bpf
sudo ./xdp_loader -d tap0 -S --filename xdp_prog_kern_03.o --progsec xdp_router -F
sudo ./xdp_prog_user -d tap0
```
		* tap0에만 붙여도 xdp 실행 가능함 
			* -S : generic mode -> -N으로 옵션 주면 Native mode
				* generic mode는 유저 프로그램 형식으로 NIC에 붙이는 형태 
				* native mode는 커널 4.후반대 이상에서 지원하는 데 커널에서 이미 빌드되어 있는 형태
				* tap0는 virtual interface라 generic mode로 해야됨
		* xdp_loader, xdp_user 둘 다 붙여줘야함. xdp_user에서 redirect map 관리 
		* tap0에 대해 tso 옵션을 꺼줘야함.
			* tso (tcp segment offload) 옵션은 NIC에서 큰 데이터 청크를 TCP 세그먼트로 나누어서 전송하도록 하는 옵션인데, 이 옵션을 키면 xdp의 redirect 동작에 영향을 미치는 것으로 판단됨 
				* 그 이유는 xdp를 이용해서 netperf 패킷을 주고 받을 때 src가 microvm, dest microvm 외부 NIC 주소로 되어야 하는데 tso 옵션을 끄지 않으면 일부 패킷의 src 주소가 외부 NIC으로 바뀌면서 microvm에서 패킷 수신을 하지 못함
				* tso 옵션을 끄면 NIC에서 하던 데이터 청크 세분화 작업을 cpu에서 할 수 있음
			* microvm 외부 (호스트 서버)
				* ethtool -K tap0 tso off
			* microvm 내부 (firecracker 내부)
				* ethtool -K eth0 tso off
			* firecracker를 켜고 설정해야 함
				* ethtool -k [네트워크 인터페이스] 를 이용하여 제대로 옵션이 꺼졌는지 확인 가능
* microvm 내부에서 netperf 실행 [firecracker 실험 방법과 동일]
	* sh  run_host.sh
		* 4개의 netperf thread를 실행하고, 64B or 16KB로 실험 진행 
		* vnstat으로 microvm 내부의 네트워크 인터페이스에 대해 네트워크 성능 측정 
		* microvm 외부에서 pidstat, vnstat, mpstat을 이용하여 네트워크 및 CPU 사용량 측정 
* microvm 외부에서 성능 측정 [firecracker 실험 방법과 동일]
	* microvm 내부의 run_host.sh에서 다음 스크립트를 실행함
		* /home/fire/eskim/firecracker/2020nascar/test_f/eskim/run_host.sh
			* cpu, network 성능 측정 및 perf data 생성 
			* flame graph 생성
* 실험 후 xdp unload를 할 수 있는데 virtual network interface에 대해서는 unload가 잘 되지 않는 듯함
	* sh unload_xdp.sh

## kata 실험 방법
* kata 설치 및 kata-runtime 설정
	* [documentation/ubuntu-installation-guide.md at master · kata-containers/documentation · GitHub](https://github.com/kata-containers/documentation/blob/master/install/ubuntu-installation-guide.md)
	* docker에서 환경설정하면 됨
		* default-runtime : kata-runtime (위 git에도 나와있음)
* kafe 실험을 위한 ubuntu 이미지 다운로드 및 실행
```
docker pull dkdla58/ubuntu:kata_expe
#처음 실행시
docker run --name kata_expe -it dkdla58/ubuntu:kata_expe /bin/bash
#CPU 갯수 할당 - 이 실험에서는 8개 core 할당
docker update --cpus [CPU 수] kata_expe
#이후 실행시
docker restart kata_expe
docker exec -it kata_expe /bin/bash
```
	* CPU core가 제대로 설정되었는지 확인하고 싶으면 아래의 커맨드를 실행시켜 Nanocpus 부분을 확인하면 됨
	`docker inspect kata_expe`
* kata 실험 스크립트 실행
	* 스크립트 위치 : kata container 내부 -> cd ~/eskim
	* sh run_host.sh -> netperf 실행 후 결과 저장 및 kata container 외부에서 run_host_container.sh 실행 [container 내부, 호스트 서버에서 성능 측정]
	* pidstat, mpstat, vnstat으로 cpu, network 성능 측정 및 perf data 수집
 
## 라즈베리파이에서 fc, xdp_fc 실험 방법
### 라즈베리파이 실험 환경
* 4 cores CPU, 1GbE network interface, 4GB memory
* 리눅스 커널 버전 : 5.13.0-1009-raspi
* 우분투 버전 : 20.04
* firecracker 버전 : 0.25.1
* firectl 버전 : 0.1.0
* kata 버전 : 1.11.2 (arm64)
* microvm 커널 버전 : 4.14.174+
* netperf 버전 : 2.6.0

### fc 실험 방법  
* 라즈베리파이 디렉토리 -> /home/oslab/eskim
* 서버에서 firecracker 설치하는것과 같은 방법으로 설치. -> architecture 버전만 aarch64로 맞춰서 설치
* 라즈베리파이에서 사용가능한 CPU core가 4개이므로 할당 CPU를 1core, 2cores, 4cores로 할당해서 실험
	* 이에 맞춰 thread 수도 1 core - 1 thread, / 2 cores - 1 thread, 2 threads / 4 cores - 2 threads 로 실험 진행
* 메모리는 2GB 할당
* 실험 방법 
	* 64B, 16KB TCP packet을 1번 서버(netserver)로 전송
	* 55초씩 3번 실험 진행
* fc_start.sh 에서 --ncpus 수정해서 실험 진행 
* microvm 내부에서 64B_1thread, 64B_2thread, 16KB_1thread, 16KB_2thread 별 스크립트 실행하여 실험 진행
	* 스크립트 실행 시 microvm 내부에서 netperf, vnstat이 실행되어 결과 값 저장
	* 호스트 서버의 ./result 디렉토리에서 run_host.sh를 실행시켜, pidstat, mpstat, vnstat으로 CPU 및 네트워크 사용량 측정

### xdp_fc 실험 방법
* xdp 디렉토리 : /home/oslab/eskim/xdp-tutorial/packet-solutions
* 서버에서 xdp를 적용할 때처럼 git clone 해서 xdp 설치 및 빌드를 진행
* 빌드시 에러 발생할 수 있음
[image:80E26D09-28E8-4E4C-B8EF-4D3CBEACC516-2695-00005D62E760E43B/BF21C775-694C-4EA5-B019-936AF6165366.png]
* 이런 상황 발생시 asm 라이브러리가 존재하는 디렉토리에 대해 심볼릭 링크를 걸어주면 해결 가능
	* cd /usr/include
	* ln -s [asm 라이브라리가 있는 디렉토리] asm 
* 실험 방법 
	* 64B, 16KB TCP packet을 1번 서버(netserver)로 전송
	* 55초씩 3번 실험 진행
* 우분투 서버에 netserver 실행 및 라우트 설정
	* 우분투 서버 ip : 163.152.161.155(10.0.0.10) 
	* id : oslab, password : oslab123
	* netserver 실행 및 라우트 설정은 위의 1번 서버 설정 과정과 동일
* sh load_xdp.sh 실행하여 xdp attach 함
	* 라즈베리파이에서는 tap0와 외부와 연결된 NIC 둘 다 xdp를 붙여야 통신이 됨
* tso 옵션 끈 후 microvm 내에서 스크립트 실행하여 실험 진행

## 실험 데이터 및 결과
* 서버 실험 데이터 : /home/fire/eskim/firecracker/2020nascar/test_f/eskim/new_kernel_211123 
	* default : firecracker 실험 데이터 
	* xdp : xdp를 NIC에 붙였을 때 firecracker 실험 데이터
	* kata_with_vhost : kata 실험 데이터
* 서버 실험 결과 
	* kata가 firecracker에 비해 50% 높은 CPU 사용량으로 11% 높은 성능을 가짐
	* xdp_firecracker가 20% 높은 CPU 사용량으로 기존 firecracker의 네트워크 성능을 45% 개선 
	* xdp_firecracker가 kata에 비해 60% 낮은 CPU 사용량으로 네트워크 성능을 38% 개선
	* 네트워크 처리량은 xdp_fc (889 Mbps) > kata (551 Mbps) > default_fc (490 Mbps)
	* CPU 사용량은 kata (643 %) > xdp_fc (401 %) > default_fc (322 %) 입니다. 
[image:5B468C3C-D5B3-447F-A158-547C578499B4-2695-00005FB8195B075A/303B17FA-55C2-4490-AC32-574C1327C5AB.png]

* 라즈베리파이 실험 데이터 : /home/oslab/eskim/results/1cores,2cores,4cores/fc,xdp_16KB,64B_1thread,2thread
	* fc_16KB_1thread : firecracker에서 netperf thread 1개로 16KB TCP packet을 전송
	* xdp_64B_2thread : xdp를 NIC에 붙인 상태에서 firecracker에서 netperf thread 2개로 64B TCP packet을 전송
* 라즈베리파이 실험 결과 
[image:164C20FC-623B-4E99-B837-83F1E0682212-2695-00005F1303B3120B/F346ED72-F062-4C1A-87C1-045544E6A0A7.png]
[image:4CDE08EB-C3D6-4282-9045-A5D053B60895-2695-00005F13DC3C3D4B/A9BD5FF9-ACA1-43A7-8EBA-CA7288B4338C.png]
	* 64B, 16KB 일 때 2core를 사용하는 경우를 제외한 모든 경우에서 xdp가 더 높은 성능을 보임. 
	* [64B] xdp 적용을 했을 시 network throughput이 1core_1thread (46% 증가) > 4core_2thread (10% 증가) > 2core_2thread (16% 감소) > 2core_1thread (35% 감소)
	* [16KB] xdp 적용을 했을 시 network throughput이 1core_1thread (80% 증가) > 4core_2thread (75% 증가) > 2core_2thread (34% 감소) > 2core_1thread (45% 감소)
	* 전체적으로 봤을 때 1core_1thread 혹은 4core_2thread를 쓰는 것이 xdp의 성능 개선을 보여줄 수 있을 것으로 보입니다. 

## 추가 내용 정리
* xdp 사용시 cpu를 어느정도 선(5 core까지였던 것으로 확인)까지 많이 쓰면 성능이 firecracker보다 잘 나옴 
* AF_XDP 라는 소켓이 있는데 이걸 사용하면 XDP 프로그램이 프레임을 user space application의 메모리 버퍼로 리다이렉트하기 때문에 메모리 복사 없이 패킷 전송이 가능하여 더 높은 성능으로 패킷 처리를 할 수 있다고 함. 

## 레퍼런스
* firecracker : [GitHub - firecracker-microvm/firecracker: Secure and fast microVMs for serverless computing.](https://github.com/firecracker-microvm/firecracker)
* firectl : [GitHub - firecracker-microvm/firectl: firectl is a command-line tool to run Firecracker microVMs](https://github.com/firecracker-microvm/firectl)
* xdp_github : [GitHub - xdp-project/xdp-tutorial: XDP tutorial](https://github.com/xdp-project/xdp-tutorial) (여기에 xdp pass부터 xdp redirect, AF_XDP까지 tutorial이 잘되어 있음)
* xdp 논문 : [The eXpress data path | Proceedings of the 14th International Conference on emerging Networking EXperiments and Technologies](https://dl.acm.org/doi/abs/10.1145/3281411.3281443)

