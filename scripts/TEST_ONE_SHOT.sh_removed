#!/bin/bash

function usage() {
    echo ""
    echo "Usage: $(basename $0) <option>"
    echo "  -h: print help info"
    echo "  -m: whether to use atop to monitor CPU/MEM/DSK; shall be \"y\" or \"n\"; default \"y\""
    echo "  -l: load - sending how many workflows to engine at one time; shall be integer; default 100"
    echo "  -i: iteration - executing repeatly how many times upon the load; shall be integer; default 1"
    echo "  -w: worker number - how many workers do you want; shall be integer; default 1"
    echo "example: ./TEST_ONE_SHOT.sh -l 1000 -i 20 -w 3 -m y"
    echo '         1000 workflows each time, repeat 20 times(20000 workflows will be hanled totally),' 
    echo '         use 3 workers, use atop to monitor CPU/MEM/DSK'
    echo ""
    echo "get more information about BOSS performance testing:"
    echo 'http://wiki.meego.com/Release_Infrastructure/BOSS/Performance'
    echo 'http://wiki.meego.com/Release_Infrastructure/BOSS/Performance/Results'
    echo ""
}

load="100"
iteration="1"
monitor="y"
worker="1"
start_t=`date +%Y%m%d-%H%M%S`

while [ $# -gt 0 ]
do
    case $1 in
        "-h")
            usage
            exit 0
            ;;
        "-l")
            if [[ "$2" =~ ^[0-9]+$ ]];then 
                load=$2
            else
                echo "You need to specify load number"
                exit 1
            fi
            shift 2
            ;;
        "-i")
            if [[ "$2" =~ ^[0-9]+$ ]];then 
                iteration=$2
            else
                echo "You need to specify iteration number"
                exit 1
            fi
            shift 2
            ;;
        "-m")
            if [ "$2" == "y" -o "$2" == "n" ];then
                monitor=$2
            else
                echo "You need to specify y/n to enable/disable monitor(atop)"
                exit 1
            fi
            shift 2   
            ;;     
        "-w")
            if [[ "$2" =~ ^[0-9]+$ ]];then 
                worker=$2
            else
                echo "You need to specify worker number"
                exit 1
            fi
            shift 2
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
#echo $load $iteration $monitor $worker_cnt
#exit

# setup fifo pipe
if [ -p /tmp/boss.pipe ];then
    echo "delete /tmp/boss.pipe"
    rm -rf /tmp/boss.pipe
fi
echo "mkfifo"
mkfifo /tmp/boss.pipe

# start monitor
if [ "$monitor" == "y" ];then
    echo "Start atop monitor..."
    xterm -T ATOP -e "rm -rf /tmp/atop.raw && atop -w /tmp/atop.raw 5" 2>/dev/null &
    pids=("${pids[@]}" $!)
fi

# start engine
echo "Start engine..."
nohup xterm -T LAUNCH -e "ruby launch.rb" 2>/dev/null &
pids=("${pids[@]}" $!)

# start extra workers
if [ $worker -gt 1 ];then 
    ((cnt=$worker-1))
    echo "start extra $cnt workers"
    while [ $cnt -gt 0 ]
    do
        nohup xterm -T WORKMAN$cnt -e "ruby workman.rb" 2>/dev/null &
        pids=("${pids[@]}" $!)
        ((cnt=$cnt-1))
    done 
fi

# start participants
echo "Start participant: sizer..."
nohup xterm -T SIZER -e "python participant_sizer.py" 2>/dev/null &
pids=("${pids[@]}" $!)

echo "Start participant: resizer..."
nohup xterm -T RESIZER -e "python participant_resizer.py" 2>/dev/null &
pids=("${pids[@]}" $!)

# start client
echo "Start client..."
sleep 3
# Start a client
nohup xterm -T CLIENT -e "python client.py $load $iteration" 2>/dev/null &
pids=("${pids[@]}" $!)

# wait for finish
echo "waiting for test finishing"
while read msg < /tmp/boss.pipe
do 
    echo $msg
    if [ "$msg" == "finish" ];then 
        break 
    fi
done

# analyze atop result
if [ "$monitor" == "y" ];then
    echo "analyzing atop results"
    ./analyze_load.sh /tmp/atop.raw 00:00 23:59
fi

# collect results to one folder
dir="./result_load${load}_iteration${iteration}_workers${worker}_${start_t}"
mkdir $dir
if [ -d $dir ];then
    mv ./LOG ./cpu.data ./mem.data ./dsk.data $dir
fi

# clean work
echo "Clean..."
echo "These processes will be destroyed: ${pids[@]}"
for pid in ${pids[@]}
do
    kill -9 $pid
done



