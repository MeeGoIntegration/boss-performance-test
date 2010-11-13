require 'amqp'
require 'mq'
require 'json'

$cfg = {
  "amqp"=>{
           "host"=>"localhost",
           "user"=>"boss",
           "pass"=>"boss",
           "vhost"=>"boss"
          },
  "case_name"=>"case_001",
  "channel"=>"single",
  "load"=>1,
  "iteration"=>1,
  "iteration_timeout"=>600,
  "output"=>"/root/results/case_001"
}

$workflow = {
      'definition' => 
          'Ruote.process_definition :name => "boss-performance-test" do
	      sequence do
                pilot
                pilot
	      end
          end',
      'fields' => {
	  'dirty' => 0,
          'iteration' => 0,
          'load' => 0,
	  'version' => 0
        }
    }

$workflow2 = '
Ruote.process_definition :name => "boss-performance-test" do
  sequence do
    pilot
    pilot
  end
end'

$workflow3 = {
      "definition" => "
	  Ruote.process_definition :name => 'boss-performance-test' do
	      sequence do
                pilot
                pilot
	      end
          end"
      }

AMQP.settings[:host] = 'localhost'
AMQP.settings[:user] = 'boss'
AMQP.settings[:pass] = 'boss'
AMQP.settings[:vhost] = 'boss'


#AMQP.start(:host => "localhost", :port=>"5672", :user=>"boss", :pass=>"boss", :vhost=>"boss") do
#AMQP.start(:host=>"localhost", :user=>"boss", :pass=>"boss", :vhost=>"boss") do
AMQP.start do
  q = MQ.queue('ruote_workitems')
  #msg = JSON 'definition' => "ABC"
  #p msg
  #q.publish(msg)
  puts "-----------------------------" 
  
  $ret = "none"
  
  $workflow['fields']['case_name']=$cfg['case_name']
  $workflow['fields']['output'] = $cfg['output']
  
  $cfg['iteration'].times do |j|
    $workflow['fields']['iteration'] = j+1
    timer = 0
    $cfg['load'].times do |i|
      $workflow['fields']['version'] = (i+1)
      pdef = JSON 'definition' => "ABC"
      q.publish(pdef)
      p pdef
      puts "Request #{i+1}"
    end
    puts "-----------waiting------------"
    
    while true
      if not File.exists?($cfg['output']+"/iteration_finish")
	#sleep 1
	timer = timer + 1
	print "\rwaiting time: #{timer}"
	if timer > $cfg['iteration_timeout']
	  puts "Error: time out"
	  $ret = "timeout"
	  break
	end
      else
	$ret = "finish"
	File.unlink($cfg['output']+"/iteration_finish")
	break
      end
    end
    
    if $ret == "timeout"
      break
    end
  end
  
  f = File.open($cfg['output']+"/run.pipe", 'w')
  f.write($ret)
  f.close  
end