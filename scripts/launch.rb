# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'ruote'
require 'ruote/storage/fs_storage'
require 'ruote-amqp'
require 'optparse'

$engine = nil
$cfg = nil
$storage_name = nil
$participant_names = nil
$log_dir = "./.results_msg"

#if ARGV.size > 0
#    $msg_log_dir = ARGV[0]
#end

def load_config
    file = File.new("./global.config")
    $cfg = eval(file.read)
    #p $cfg
end

def parse_options
    OptionParser.new do |opt|
        opt.banner = "Usage: launch.rb [options]"
        opt.on('-s Storage') { |storage| p storage; $storage_name = storage}
        opt.on('-l Log') { |log| p log; $log_dir = log}
        opt.on('-p Participant names') { |par_name| p par_name; $participant_names = eval(par_name)}
        opt.on_tail("-h", "--help", "Show help") { puts opt; exit }
        opt.parse!
    end

end

#  engine = Ruote::Engine.new(
#    Ruote::Worker.new(
#      Ruote::FsStorage.new('/tmp/work')
#    )
#  )
#end


def init_engine
    if $cfg['storage']
        storage_list = $cfg['storage']
	#p storage_list
	#p $storage_name
        storage = storage_list[$storage_name]
        #p storage['class']
	#p $log_dir
        $engine = Ruote::Engine.new(Ruote::Worker.new(eval(storage["class"]+".new('"+$log_dir+"')")))
	if $cfg['engine_logger']
	    logger = $cfg['engine_logger']
            $engine.add_service('s_logger', logger['name'], logger['class'], logger['log'])
	end
    end
end

def register_participants
    if $cfg['participant']
        part_list = $cfg['participant']
        $participant_names.each{
            |name|
            part = part_list[name]
            #p part
            $engine.register_participant(name, eval(part["class"]),
                                         :command => part["command"], :queue => part["queue"])
        }
    end
end




load_config()
parse_options()
init_engine()

p $cfg['amqp']
AMQP.settings[:host] = $cfg['amqp']['host']
AMQP.settings[:user] = $cfg['amqp']['user']
AMQP.settings[:pass] = $cfg['amqp']['pass']
AMQP.settings[:vhost] = $cfg['amqp']['vhost']
#AMQP.logging = config['amqp']['logging']

# This spawns a thread which listens for amqp responses
RuoteAMQP::Receiver.new($engine, :launchitems => true)

# This registers a general purpose 'remote' participant
$engine.register_participant('remote', RuoteAMQP::Participant)

register_participants()

puts "start engine..."
$engine.join()

