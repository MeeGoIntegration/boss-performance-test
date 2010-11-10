# To change this template, choose Tools | Templates
# and open the template in the editor.
require 'rubygems'
require 'ruote'
require 'ruote-amqp'
require 'optparse'

$case_conf = nil
$global_conf = nil
$engine = nil
$file = nil
$out = "."

#=================== Section: Function Definition =============================

# Function to:
#   - load config file to memory
def load_config(file)
    f = File.open(file)
    cfg = eval(f.read)
    return cfg 
end

# Function to:
#   - parse command line options
def parse_options
    OptionParser.new do |opt|
        opt.banner = "Usage: launch.rb [options]"
        opt.on('-c test config file') { |file| $file = file }
        opt.on('-o output folder, also using as workarea') { |out| $out = out }
        opt.on_tail("-h", "--help", "Show help") { puts opt; exit }
        opt.parse!
    end
end

# Function to:
#   - initialize engine
def init_engine
    if $global_conf['storage']
        storage_list = $global_conf['storage']
        storage_name = $case_conf['storage'].downcase
        storage = storage_list[storage_name]
        storage_dir = $out + "/storage"
        
        if File.directory?(storage_dir)
            `rm -rf #{storage_dir}`
        end
        `mkdir #{storage_dir}`
        
        # example: Ruote::FsStorage.new('./tmp/storage')
        load storage["file"]
        str = storage["class"]+".new('"+storage_dir+"')"
        #p str
        $engine = Ruote::Engine.new(Ruote::Worker.new(eval(str)))
	if $global_conf['engine_logger']
	    logger = $global_conf['engine_logger']
            $engine.add_service('s_logger', logger['path'], logger['class'], {"out"=>$out, "name"=>"Worker-default"})
	    #run extra worker
	    $case_conf['extra_worker'].times do |n|
		Thread.new{
		    workman = Ruote::Worker.new(eval(str));
		    workman.context.add_service('s_logger', logger['path'], logger['class'], {"out"=>$out, "name"=>"Worker-#{n}"});
		    workman.run;
		}
	    end
	end
    end
end

# Function to:
#   - register participants
def register_participants
    if $global_conf['participant']
        part_list = $global_conf['participant']
        participant_names = $case_conf['participant']
        participant_names.each do |name|
            part = part_list[name.downcase]
            if part["type"] == "remote"
                $engine.register_participant(name, RuoteAMQP::Participant, 
                                             :command => part["command"], :queue => part["queue"])
            else
                load part["file"]
                $engine.register_participant(name, part["class"])
            end
        end
    end
end


#======================= Section: Execution ===================================

#== parse options
parse_options()

#== get global config and test case config
$global_conf = load_config("./global.config")
$case_conf = load_config($file)

#== initialize engine
init_engine()

#== set AMQP upon config file
AMQP.settings[:host] = $global_conf['amqp']['host']
AMQP.settings[:user] = $global_conf['amqp']['user']
AMQP.settings[:pass] = $global_conf['amqp']['pass']
AMQP.settings[:vhost] = $global_conf['amqp']['vhost']
#AMQP.logging = config['amqp']['logging']

#== get new receiver thread to listen
RuoteAMQP::Receiver.new($engine, :launchitems => true)

#== register a participant which will be the proxy for real remote participants  
$engine.register_participant('remote', RuoteAMQP::Participant)

#== register real participants
register_participants()

#== start engine
puts "start engine..."
$engine.join()

