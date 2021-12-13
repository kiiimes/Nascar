#!/bin/sh
PID=`pgrep firecracker`
pidstat -t -p $PID 55 1 >> pidstat_1.txt &
#pidstat -p 5800 55 1 >> pidstat.txt &
#pidstat -p 16326 55 1 >> pidstat.txt &
mpstat 55 1 >> mpstat_1.txt &
vnstat -tr 55 -i eth0 >> vnstat_eth0_1.txt &
vnstat -tr 55 -i tap0 >> vnstat_tap0_1.txt 
