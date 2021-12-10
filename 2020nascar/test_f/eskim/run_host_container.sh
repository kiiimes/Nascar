#!/bin/sh
PID=`pgrep qemu` 
PID2=`pgrep vhost-`
pidstat -t -p $PID 55 1 >> pidstat_3.txt &
pidstat -t -p $PID2 55 1 >> pidstat_4.txt &
#pidstat -p 5800 55 1 >> pidstat.txt &
#pidstat -p 16326 55 1 >> pidstat.txt &
mpstat 55 1 >> mpstat_3.txt &
vnstat -tr 55 -i enp2s0f1 >> vnstat_enp2s0f1_3.txt &
vnstat -tr 55 -i docker0 >> vnstat_docker0_3.txt &
#perf stat -t $PID -d -d -d -o perf_total.txt sleep 55 &
#perf stat -t $PID -e cache-misses -e cache-references -e ref-cycles -e alignment-faults -e bpf-output -e cpu-clock -e migrations -e emulation-faults -e major-faults -e minor-faults -e faults -e cycles -e L1-dcache-stores -e LLC-store-misses -e LLC-store-misses -e LLC-stores -e branch-load-misses -e branch-loads -e dTLB-store-misses -e dTLB-stores -e node-load-misses -e node-loads-misses -e node-loads -e node-store-misses -e node-stores -o perf_others.txt sleep 55 &
perf record -F 99 -ag -p $PID -o docker_64B.data sleep 55 &
perf record -F 99 -ag -o host_64B.data sleep 55

sudo perf script -i docker_64B.data | ../../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
cat out.perf-folded | ../../../../FlameGraph/flamegraph.pl > docker_64B.svg
sudo perf script -i host_64B.data | ../../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
cat out.perf-folded | ../../../../FlameGraph/flamegraph.pl > host_64B.svg
