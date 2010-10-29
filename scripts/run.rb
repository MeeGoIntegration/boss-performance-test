#!/usr/bin/env ruby
# This script supposes to get one parameter: a test case config file

###################### Section: Function Definition ####################

require 'optparse'

$file = nil
$out = nil
$participants = Hash.new
$pipe = nil
$config = nil
$global = nil

# function to:
#   - parse command options
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

# function to 
#   - execute command in sub-process 
#   note: pid returned by "fork" is always not the final pid of cmd in sub-process;
#         and the interesting thing is:
#           - for simple command "xterm ping xxxx" the pid returned by "fork" is correct
#           - for command with "&" to run backgroud, the pid returned by "fork" is incorrect
#         finally we use shell command "echo $!" to get pid
def launch_process(cmd, title)
    pid = fork
    if not pid
        puts "launching process: #{title}"
        cmd_pid = " echo $! >#{$out}/#{title}.pid"
        cmd = cmd + cmd_pid
        p cmd
        #exec("xterm -T ccc -e \"ping www.baidu.com\" &")
        exec(cmd)
    end
end

# function to:
#   - load config file to memory
def load_config(file)
    f = File.open(file)
    cfg = eval(f.read)
    return cfg 
end

# function to:
#   - kill all processes represented by *.pid files in $out folder
#   - delete all pid files
def kill_processes
    pid_files = Dir["#{$out}/*.pid"]
    pid_files.each do |file|
        f = File.open(file)
        pid = f.read
        file_prefix = File.basename(file, '.pid')
        puts "killing process: #{file_prefix}"
        `kill -9 #{pid}`
        #TODO: verify kill result
        File.delete(file)
    end
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
    
    # get participants hash
    case_conf = load_config($file)
    global_conf = load_config("./global.config")
    if case_conf['participant'].class != Array
        puts "no participants found, check!"
        exit
    end
    case_conf['participant'].each do |par|
        $participants[par] = global_conf['participant'][par]['path']
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

#== transfer relative path to fully qualified path; and change directory 
$file = File.expand_path($file)
$out = File.expand_path($out)
dir = File.dirname($0)
Dir.chdir(dir)

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
$participants.each do |par, path|
    cmd = "xterm -T #{par} -e \"#{path}\" 2>/dev/null &"
    launch_process(cmd, par)
end

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

#== clean
#   - all processes and their *.pid files)
#   - delete pipe
kill_processes
File.delete($pipe)

#== finished!
puts "===== test case finished ====="
exit
