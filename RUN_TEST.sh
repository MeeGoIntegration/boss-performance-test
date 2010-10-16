#!/bin/bash

# Start (a) workflow engine
rm -rf ./tmp
rm -rf ./.launch
rm -rf ./LOG
rm -rf ./top_stat

if [$1 = '']
then
$1 = 1
fi

echo "Start atop monitor"
nohup xterm -T ATOP -e "rm -rf /tmp/atop.raw && atop -w /tmp/atop.raw 5" 2>/dev/null &

echo "Start a workflow engine..."
nohup xterm -T LAUNCH -e "ruby launch.rb $2" 2>/dev/null &
#sleep 1

echo "Start another worker..."
#nohup xterm -T WORKMAN -e "ruby workman.rb" 2>/dev/null &
#nohup xterm -T WORKMAN2 -e "ruby workman.rb" 2>/dev/null &
#nohup xterm -T WORKMAN3 -e "ruby workman.rb" 2>/dev/null &

# Start a python participant called sizer
echo "Start a python participant called sizer..."
nohup xterm -T SIZER -e "python participant_sizer.py" 2>/dev/null &

echo "Start a python participant called resizer..."
nohup xterm -T RESIZER -e "python participant_resizer.py" 2>/dev/null &

echo "begin to send some request..."
sleep 3
# Start a client
nohup xterm -T CLIENT -e "python client.py $1 1 $2" 2>/dev/null &

# 
#echo run : demo/START.sh
#echo to start a process

