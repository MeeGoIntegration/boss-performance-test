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

load_config()

AMQP.settings[:host] = $cfg['amqp']['host']
AMQP.settings[:user] = $cfg['amqp']['user']
AMQP.settings[:pass] = $cfg['amqp']['pass']
AMQP.settings[:vhost] = $cfg['amqp']['vhost']
#AMQP.logging = config['amqp']['logging']

file = File.new($cfg['storage_conf_file'])
storages = eval(file.read)
if $cfg['storage']
  storage = storages[$cfg['storage']]
  worker = Ruote::Worker.new(Ruote::FsStorage.new('./.tmp', 's_logger' => ['./persist_logger', 'Ruote::PersistLogger', $msg_log_dir]))
  worker.run

  #$engine.add_service('s_logger', $cfg['engine_logger'][0], $cfg['engine_logger'][1], $msg_log_dir) if $cfg['engine_logger']
  #$engine.add_service('s_logger', '/home/weifeyao/boss/test/git/boss-performance-test/dbm_logger', 'Ruote::DBMLogger')
end


#/root/boss_scripts/test/analyze_results_v0.2.rb

