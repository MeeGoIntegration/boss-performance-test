#!/usr/bin/env ruby
# This script supposes to get one parameter: a test case config file

###################### Section: Function Definition ####################

$pids = Array.new

# function to execute command in sub-process 
def launch_process(cmd, title)
    pid = fork
    if not pid
        puts "launching process: #{title}"
        p cmd
        exec('xterm')
    end
    # add pid to pid list
    $pids.push(pid)
end


$file = false
$config = false
$global = false
$out = false
$worker = false
$load = false
$iteration = false
$channel = false
$workflow = false
$participants = Hash.new
$pipe = false

# function to:
#   - get and verify parameters from config files
#   - setup pipe between this script and client
def preprocess()
    # get config file name
    if not ARGV.size == 1
        puts "wrong argument number, only one test case config can be accepted"
        exit
    else
        $file = ARGV[0]
    end

    # get config info
    if not File.exist?($file)
        puts "file #{$file} does not exist, check its path!"
        exit
    end
    f = File.open($file)
    $config = eval(f.read)
    #p $config

    # get output folder
    $out = $config['output']
    if not File.directory?($out)
        puts "wrong output path: #{$out}, check its path!"
        exit
    end

    # get worker number
    $worker = $config['worker']
    if $worker < 1
        puts "wrong worker number: #{$worker}, check!"
        exit
    end

    # get load number
    $load = $config['load']
    if $load < 1
        puts "wrong load number: #{$load}, check!"
        exit
    end

    # get iteration number
    $iteration = $config['iteration']
    if $iteration < 1
        puts "wrong iteration number: #{$load}, check!"
        exit
    end
    
    # get channel
    $channel = $config['channel']
    if not $channel == "single" and not $channel == "multiple"  
        puts "wrong channel: #{$channel}, check!"
        exit
    end

    # get workflow
    $workflow = $config['workflow']
    if not $workflow.class == Hash
        puts "wrong workflow: #{$workflow}, check!"
        exit
    end

    # get global config info
    $global = eval(File.open('global.config').read)

    # get participants
    $config['participant'].each do |par|
        file = $global['participant'][par]['path']
        p file
        if not File.exist?(file)
            puts "wrong participant: #{par}, check!"
            exit
        end
        $participants[par] = file
    end

    
    # setup pipe
    $pipe = "#{File.basename($file)}.pipe"
    $pipe = "#{$out}/#{$pipe}" 
    if File.exist?($pipe)
        File.delete($pipe)
    end
    `mkfifo #{$pipe}`
    if not File.exist?($pipe)
        puts "failed to create pipe: #{$pipe}, check!"
        exit
    end
end


###################### Section: Execution ####################

#== preprocess
preprocess()

#== launch atop process
atop_data = "#{$out}/atop.raw"
cmd = "xterm -T atop -e \"rm -rf #{atop_data} && atop -w #{atop_data} 5\" 2>/dev/null &"
launch_process(cmd, 'atop')


#== launch engine process
cmd = "xterm -T engine -e \"ruby launch.rb #{$out}\" 2>/dev/null &"
launch_process(cmd, 'engine')

#== launch extra workers
extra_worker = $worker - 1
cnt = 1
until cnt > extra_worker do
    cmd = "xterm -T WORKMAN#{cnt} -e \"ruby workman.rb\" 2>/dev/null &" 
    launch_process(cmd, "WORKMAN#{cnt}")
    cnt += 1
end


#== launch participant processes
$participants.each do |par, file|
    cmd = "xterm -T #{par} -e \"python #{file}\" 2>/dev/null &"
    launch_process(cmd, "participant: #{par}")
end


#== launch client process
`sleep 3`
cmd = "xterm -T client -e \"python client.py $load $iteration $channel $out\" 2>/dev/null &"
launch_process(cmd, "client")


#== wait for test finish(signal from client process) 
f = File.open($pipe, 'r+')
while true
    str = f.readline
    if str =~ /^finish/i
        puts "got finish message!"
        break
    end
end 


#== analyze atop data
cmd = "./analyze_load.sh -r #{atop_data} -b 00:00 -e 23:59 -o #{$out}"
p cmd
`#{cmd}`


#== clean(kill processes,delete temp files...)
$pids.each do |p|
    ret = `kill -9 #{p}`
end
File.delete($pipe)

puts "===== test case finished ====="
exit
