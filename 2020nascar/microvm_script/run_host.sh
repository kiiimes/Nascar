#!/bin/sh
#netperf -H 10.0.0.25 -p 1 -l 60 -- -m 64 > tcp_nonxdp1.txt &
netperf -H 10.0.0.25 -l 60 -p 1 -- -m 64 > netperf1.txt & netperf -H 10.0.0.25 -l 60 -p 2 -- -m 64 > netperf2.txt &netperf -H 10.0.0.25 -l 60 -p 3 -- -m 64 > netperf3.txt &netperf -H 10.0.0.25 -l 60 -p 4 -- -m 64 > netperf4.txt&
vnstat -tr 55 -i eth0 >> vnstat_eth0_3.txt &
sshpass -p 1 ssh -t -t fire@163.152.20.220 "cd /home/fire/eskim/firecracker/2020nascar/test_f/eskim && echo '1' | sudo -S sh run_host.sh"
scp *.txt fire@163.152.20.220:/home/fire/eskim/firecracker/2020nascar/test_f/eskim
