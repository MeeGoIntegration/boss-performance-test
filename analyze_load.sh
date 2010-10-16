#!/usr/bin/sh

echo "input argu:" $1 $2 $3

raw=$1
startt=$2
endt=$3
out_cpu=./cpu.data
out_mem=./mem.data
out_dsk=./dsk.data
touch $out_cpu $out_mem $out_dsk
reg="\% ruby.*launch.rb\|^ATOP"

# inject config patter into .atoprc to fit following regular expression
if [ -e ~/.atoprc ];then
    mv -f ~/.atoprc ~/.atoprc.bak
fi
echo "ownprocline PID:50 RSIZE:45 SORTITEM:18 COMMAND-LINE:50" >> ~/.atoprc

# get CPU load
out=$out_cpu
echo "CPU load for engine" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -C -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {printf "\t"$3}' >> $out

# get DSK load
out=$out_dsk
echo "DSK load for engine" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -D -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {printf "\t"$3}' >> $out

# get MEM load
out=$out_mem
echo "MEM load for engine" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {if($2~/K$/) printf "\t"$2/1000; else printf "\t"$2/1}' >> $out

