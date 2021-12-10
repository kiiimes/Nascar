#!/bin/sh
PID=`pgrep firecracker` 
pidstat -t -p $PID 55 1 >> pidstat_3.txt &
#pidstat -p 5800 55 1 >> pidstat.txt &
#pidstat -p 16326 55 1 >> pidstat.txt &
mpstat 55 1 >> mpstat_3.txt &
vnstat -tr 55 -i enp2s0f1 >> vnstat_enp2s0f1_3.txt &
vnstat -tr 55 -i tap0 >> vnstat_tap0_3.txt &
perf stat -e ‘kvm:*’ -a -o perf_kvm.txt sleep 55 &
perf stat -t $PID -d -d -d -o perf_total.txt sleep 55 &
perf stat -t $PID -e cache-misses -e cache-references -e ref-cycles -e alignment-faults -e bpf-output -e cpu-clock -e migrations -e emulation-faults -e major-faults -e minor-faults -e faults -e cycles -e L1-dcache-stores -e LLC-store-misses -e LLC-store-misses -e LLC-stores -e branch-load-misses -e branch-loads -e dTLB-store-misses -e dTLB-stores -e node-load-misses -e node-loads-misses -e node-loads -e node-store-misses -e node-stores -o perf_others.txt sleep 55 &
perf record -F 99 -ag -p $PID -o fire_16K.data sleep 55 &
perf record -F 99 -ag -o host_f_16K.data sleep 55

sudo perf script -i fire_16K.data | ../../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
cat out.perf-folded | ../../../../FlameGraph/flamegraph.pl > fire_16K.svg
sudo perf script -i host_f_16K.data | ../../../../FlameGraph/stackcollapse-perf.pl > out.perf-folded
cat out.perf-folded | ../../../../FlameGraph/flamegraph.pl > host_f_16K.svg
