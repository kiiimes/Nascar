#!/bin/sh
#netperf -H 10.0.0.10 -p 1 -l 60 -- -m 64 > tcp_nonxdp1.txt &
netperf -H 10.0.0.10 -l 60 -p 1 > netperf1.txt & netperf -H 10.0.0.10 -l 60 -p 2 > netperf2.txt &
vnstat -tr 55 -i eth0 >> vnstat_eth0_3.txt &
sshpass -p 1 ssh -t -t oslab@[localhost IP] "cd /home/oslab/eskim/results && echo '1' | sudo -S sh run_host.sh"
scp *.txt oslab@[localhost IP]:/home/oslab/eskim/results
