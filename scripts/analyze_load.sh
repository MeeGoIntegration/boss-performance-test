#!/usr/bin/sh

function usage() {
    echo "TBD"
}

raw=""
startt="00:00"
endt="23:59"
out="."
reg="[[:digit:]]\% boss\|^ATOP"

if [ $# == 0 ];then
    usage
    exit 0
fi

while [ $# -gt 0 ]
do
    case $1 in 
        "-h")
            usage
            exit 0
           ;;
        "-r")
            if [ -e "$2" ];then
                raw="$2"
            else
                echo "wrong atop raw data, check!"
                exit 1
            fi
            shift 2
            ;;
        "-b")
            startt=$2
            shift 2
            ;;
        "-e")
            endt=$2
            shift 2
            ;;  
        "-o")
            if [ -d "$2" ];then
                out="$2"
            else
                echo "wrong output path, check!"
            fi
            shift 2
            ;;
        *)
            usage
            exit 1
            ;;
    esac 
done

out_cpu="${out}/cpu.load"
out_mem="${out}/mem.load"
out_dsk="${out}/dsk.load"
touch $out_cpu $out_mem $out_dsk

# inject config pattern into .atoprc to fit following regular expression
if [ -e ~/.atoprc ];then
    mv -f ~/.atoprc ~/.atoprc.bak
fi
echo "ownprocline PID:50 RSIZE:45 SORTITEM:18 COMMAND-LINE:50" >> ~/.atoprc

# get CPU load
out=$out_cpu
echo "CPU load for BOSS" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -C -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {printf "\t"$3}' >> $out

# get DSK load
out=$out_dsk
echo "DSK load for BOSS" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -D -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {printf "\t"$3}' >> $out

# get MEM load
out=$out_mem
echo "MEM load for BOSS" > $out
echo "start: $startt" >> $out
echo "end: $endt" >> $out
atop -o -r $raw -b $startt -e $endt |grep "$reg" | awk '/^A/{printf "\n"$5;next} {if($2~/K$/) printf "\t"$2/1000; else printf "\t"$2/1}' >> $out

