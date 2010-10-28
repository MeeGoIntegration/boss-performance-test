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


def load_config
    file = File.new("./global.config")
    $cfg = eval(file.read)

end

def parse_options
    OptionParser.new do |opt|
        opt.banner = "Usage: workman.rb [options]"
        opt.on('-s Storage') { |storage| p storage; $storage_name = storage}
        opt.on('-l Log') { |log| p log; $log_dir = log}        
        opt.on_tail("-h", "--help", "Show help") { puts opt; exit }
        opt.parse!
    end

end

load_config()
parse_options()

AMQP.settings[:host] = $cfg['amqp']['host']
AMQP.settings[:user] = $cfg['amqp']['user']
AMQP.settings[:pass] = $cfg['amqp']['pass']
AMQP.settings[:vhost] = $cfg['amqp']['vhost']
#AMQP.logging = config['amqp']['logging']

if $cfg['storage']
    storage_list = $cfg['storage']
    #p storage_list
    #p $storage_name
    storage = storage_list[$storage_name]
    worker = nil
    if $cfg['engine_logger']
        logger = $cfg['engine_logger']
	#'./.tmp', 's_logger' => ['./persist_logger', 'Ruote::PersistLogger', $msg_log_dir]
        worker = Ruote::Worker.new(eval(storage["class"]+".new('"+$log_dir+"', 's_logger'=>['"+logger['name']+"','"+logger['class']+"','"+logger['log']+"'])"))
    else
        worker = Ruote::Worker.new(eval(storage["class"]+".new('"+$log_dir+"')"))
    end
    
    if worker != nil
        worker.run
    end
end


