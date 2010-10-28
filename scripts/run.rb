#!/usr/bin/env ruby
# This script supposes to get one parameter: a test case config file

###################### Section: Function Definition ####################

require 'optparse'

$file = nil
$out = nil
$participants = Hash.new
$pipe = false
$config = false
$global = false


def parse_options
    opt = OptionParser.new 
    opt.banner = "Usage: rub.rb [options]"
    opt.on('-c test config file') { |file| $file = file }
    opt.on('-o output folder, also using as workarea') { |out| $out = out }
    opt.on_tail('-h', 'show help') {puts opt; exit} 
    opt.parse!
    
    if $file.nil?
        puts opt
        exit
    end
end

$pids = Array.new

# function to execute command in sub-process 
def launch_process(cmd, title)
    pid = fork
    if not pid
        puts "launching process: #{title}"
        p cmd
        #exec("xterm -T ccc -e \"ping www.baidu.com\"")
        exec(cmd)
    end
    # add pid to pid list
    $pids.push(pid)
end


# function to:
#   - verify config file
#   - setup pipe between this script and client
def preprocess()
    # parse options
    parse_options()
    
    # verify config file 
    if not File.exist?($file)
        puts "file #{$file} does not exist, check its path!"
        exit
    end

    # setup pipe
    $pipe = "#{$out}/run.pipe" 
    if File.exist?($pipe)
        File.delete($pipe)
    end
    `mkfifo #{$pipe}`
    if not File.exist?($pipe)
        puts "failed to create pipe: #{$pipe}, check!"
        exit
    end

    # make storage directory
    storage_dir = $out + "/storage"
    if File.directory?(storage_dir)
        `rm -rf #{storage_dir}`
    end
    `mkdir #{storage_dir}`
end


###################### Section: Execution ####################

#== parse options
parse_options()

#== preprocess
preprocess()

#== launch atop process
atop_data = "#{$out}/atop.raw"
cmd = "xterm -T atop -e \"atop -w #{atop_data} 5\" 2>/dev/null &"
launch_process(cmd, 'atop')

#== launch engine process
cmd = "xterm -T engine -e \"ruby ./launch.rb -c #{$file} -o #{$out}\" 2>/dev/null &"
launch_process(cmd, 'engine')

#== launch participant processes
#$participants.each do |par, file|
    cmd = "xterm -T sizer -e \"python participant_sizer.py\" 2>/dev/null &"
    launch_process(cmd, "participant: sizer")
    cmd = "xterm -T resizer -e \"python participant_resizer.py\" 2>/dev/null &"
    launch_process(cmd, "participant: resizer")
#end

#== launch client process
`sleep 3`
p $workflow.inspect
cmd = "xterm -T client -e \"python client.py -c #{$file} -o #{$out}\" 2>/dev/null &"
launch_process(cmd, "client")

#== wait for test finish(signal from client process) 
f = File.open($pipe, 'r+')
while true
    str = f.readline
    p str
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
p $pids
$pids.each do |p|
    ret = `kill -9 #{p}`
end
File.delete($pipe)

puts "===== test case finished ====="
exit
