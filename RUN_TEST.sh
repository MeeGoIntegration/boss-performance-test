#!/bin/bash
# Start MQ system
# ssh amqpvm tail -f /var/log/rabbitmq/rabbit.log &

# Start (a) workflow engine
echo "Start a workflow engine..."
nohup xterm -T LAUNCH -e "ruby launch.rb" 2>/dev/null &
#sleep 1

# Start a python participant called sizer
echo "Start a python participant called sizer..."
nohup xterm -T SIZER -e "python participant_sizer.py" 2>/dev/null &

echo "begin to send some request..."
sleep 3
# Start a client
nohup xterm -T CLIENT -e "python client.py $1" 2>/dev/null &

# 
#echo run : demo/START.sh
#echo to start a process

#echo "t: $1"
#echo $2
