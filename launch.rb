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
$config = nil


def load_config
  file = File.new("config_test.txt")
  $config = eval(file.read)
  #p $config if $debug
end

#  engine = Ruote::Engine.new(
#    Ruote::Worker.new(
#      Ruote::FsStorage.new('/tmp/work')
#    )
#  )
#end


def prepare_engine
  file = File.new($config['storage_conf_file'])
  storages = eval(file.read)
  if $config['storage']
    storage = storages[$config['storage']]
    #p storage['class']
    $engine = Ruote::Engine.new(Ruote::Worker.new(eval(storage['class'])))
    #$engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::FsStorage.new('/var/boss/tmp')))
    #p $config['engine_logger']
    $engine.add_service('s_logger', $config['engine_logger'][0], $config['engine_logger'][1]) if $config['engine_logger']
    #$engine.add_service('s_logger', '/home/weifeyao/boss/demo/persist_logger', 'Ruote::PersistLogger')
    #$engine.add_service('s_logger', '/home/weifeyao/boss/boss-test/ruote/ruote/lib/ruote/log/test_logger', 'Ruote::TestLogger')
  end
end

def prepare_receiver
  
end

def prepare_participants
  file = File.new($config['participants_conf_file'])
  pars = eval(file.read)
  if $config['participants']
    $config['participants'].each{
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

AMQP.settings[:host] = $config['amqp']['host']
AMQP.settings[:user] = $config['amqp']['user']
AMQP.settings[:pass] = $config['amqp']['pass']
AMQP.settings[:vhost] = $config['amqp']['vhost']
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

$engine.register_participant 'developer', DeveloperParticipant

#puts "everything is OK..." if $debug

$engine.join()

#/root/boss_scripts/test/analyze_results_v0.2.rb

