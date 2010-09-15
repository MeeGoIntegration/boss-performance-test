# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'rubygems'
#require 'bundler'
#Bundler.setup
require 'ruote'
require 'ruote/storage/fs_storage'
require 'ruote-amqp'

@participants
@storage

$debug = false
$engine = nil
$cfg = nil
$msg_log_dir = "./.results_msg"

if ARGV.size > 0
    $msg_log_dir = ARGV[0]
end

def load_config
    file = File.new("./cfg/cfg_test")
    $cfg = eval(file.read)
    #p $cfg if $debug

end

#  engine = Ruote::Engine.new(
#    Ruote::Worker.new(
#      Ruote::FsStorage.new('/tmp/work')
#    )
#  )
#end


def prepare_engine
    file = File.new($cfg['storage_conf_file'])
    storages = eval(file.read)
    if $cfg['storage']
        storage = storages[$cfg['storage']]
        #p storage['class']
        $engine = Ruote::Engine.new(Ruote::Worker.new(eval(storage['class'])))
        #$engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::FsStorage.new('/var/boss/tmp')))
        #p $cfg['engine_logger']
        #p $cfg['engine_logger'][2]
        $engine.add_service('s_logger', $cfg['engine_logger'][0], $cfg['engine_logger'][1], $msg_log_dir) if $cfg['engine_logger']
        #$engine.add_service('s_logger', '/home/weifeyao/boss/demo/persist_logger', 'Ruote::PersistLogger')
        #$engine.add_service('s_logger', '/home/weifeyao/boss/boss-test/ruote/ruote/lib/ruote/log/test_logger', 'Ruote::TestLogger')
    end
end

def prepare_receiver

end

def prepare_participants
    file = File.new($cfg['participants_conf_file'])
    pars = eval(file.read)
    if $cfg['participants']
        $cfg['participants'].each{
            |name|
            participant = pars[name]
            #p participant
            $engine.register_participant(name, eval(participant["class"]),
                                         :command => participant["command"], :queue => participant["queue"])
        }
    end
end




load_config()
prepare_engine()
prepare_receiver()

AMQP.settings[:host] = $cfg['amqp']['host']
AMQP.settings[:user] = $cfg['amqp']['user']
AMQP.settings[:pass] = $cfg['amqp']['pass']
AMQP.settings[:vhost] = $cfg['amqp']['vhost']
#AMQP.logging = config['amqp']['logging']

# This spawns a thread which listens for amqp responses
RuoteAMQP::Receiver.new($engine, :launchitems => true)

# This registers a general purpose 'remote' participant
$engine.register_participant('remote', RuoteAMQP::Participant)

prepare_participants()


# A local participant  
class DeveloperParticipant
    include Ruote::LocalParticipant

    def initialize (opts)
        @opts = opts
    end
    def consume (workitem)
        puts "I am a native participant..."
        sleep 2
        reply_to_engine(workitem)
    end
    def cancel (fei, flavour)
        # no need for an implementation, since consume replies immediately,
        # never 'holding' a workitem
    end
end

# A local participant for threads pressure testing
class ThreadTest
    include Ruote::LocalParticipant    
    @@count = 0

    def initialize (opts)
        @opts = opts
        #puts "init"
    end

    def consume(workitem)
        @@count += 1
        #puts "====consume..."
        #p workitem
        until @@count >= workitem.fields['thread_count'] do
            #puts "waiting #{@@count}"
            sleep 2
        end
        puts "--------------current thread count: #{Thread.list.size()}-------------------"
        #if (workitem.fields['version'] == "1")
            #puts "+++++++++++++++++++++++"
            #Thread.list.each {|t| p t}
            #puts "+++++++++++++++++++++++"
        #end
        #puts "===============over #{@@count}"
        reply_to_engine(workitem)
    end
    def cancel (fei, flavour)

    end
end

$engine.register_participant 'developer', DeveloperParticipant
$engine.register_participant 'blocker', ThreadTest

#puts "everything is OK..." if $debug

$engine.join()

#/root/boss_scripts/test/analyze_results_v0.2.rb

