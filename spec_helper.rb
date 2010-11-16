require 'rubygems'
require 'amqp'
require 'mq'
require 'json'
require 'spec'
require 'spec_config'

$output = $config["output"]

Spec::Runner.configure do |config|
 
	def init_AMQP
		AMQP.settings[:host] = $config["amqp"]["host"]
		AMQP.settings[:vhost] = $config["amqp"]["vhost"]
		AMQP.settings[:user] = $config["amqp"]["user"]
		AMQP.settings[:pass] = $config["amqp"]["pass"]

		Thread.new do
			Thread.abort_on_exception = true
			AMQP.start {
			}
		end
		sleep 1
		$queue = MQ.queue('ruote_workitems')
		sleep 1
	end

	def kill_processes
		pid_files = Dir["#{$output}/*.pid"]
		pid_files.each do |file|
			f = File.open(file)
			pid = f.read
			#file_prefix = File.basename(file, '.pid')
			#puts "killing process: #{file_prefix}"
			ret = false
			10.times do 
				ret = system("kill -9 #{pid}")
				break if ret
				sleep(1)
			end
			puts "ERROR: failed to kill process, please close it manually!" if not ret
			f.close()

			File.delete(file)
		end
	end

	config.before(:all) do
		puts
		print "set up results directory..."	
		Dir.mkdir($output) if not File::directory?($output)
		print "ok\n"

		print "initializing AMQP..."
		init_AMQP()
		print "ok\n"
		
		print "starting atop monitor..."
		interval = $config["atop_sample_interval"]
		cmd = "xterm -T \"atop monitor\" -e \"atop -w #{$output}/atop.raw #{interval}\" & echo $! > #{$output}/atop.pid"
		if not system(cmd)
			puts "ERROR: failed to start atop monitor! exiting..."
			exit
		end
		sleep 1
		print "ok\n"

		print "starting participant pilot..."
		cmd = "xterm -T \"participant: pilot\" -e \"python scripts/pilot.py\" & echo $! > #{$output}/pilot.pid"
		if not system(cmd)
			puts "ERROR: failed to start participant pilot! exiting..."
			exit
		end
		print "ok\n"

		puts "staring running test cases..."
	end

	config.after(:all) do
		print "\nclean..."
		kill_processes()	
		print "ok\n"
	end

	config.before(:each) do
		puts
		puts "+++++++++++++++++++++++++"
		puts "running new test case..."
		puts "+++++++++++++++++++++++++"
		puts
	end

	config.after(:each) do
		puts
		puts "+++++++++++++++++++++++++"
		puts "finished!"
		puts "+++++++++++++++++++++++++"
		puts
	end
end


class MyRunner
	
	def initialize(options)
		@case_name = options["case_name"]
		@iteration = options["iteration"]
		@load = options["load"]
		@timeout = options["iteration_timeout"] # minutes
		@timeout = @timeout * 60 # seconds
		get_output()
		@workflow = Hash.new
		get_workflow(options["workflow"])
	end

	def get_output()
		@output = $output + "/#{@case_name}"
		# if directory exists, making new directory with timestamp rather than deleting it
		if File.directory?(@output)
			t = Time.now
			@output = @output + "_" + t.strftime("%Y%m%d_%H%M%S")
		end
		Dir.mkdir(@output) 
	end

	def get_workflow(file)
		workflow_core = File.open(file).read()
		@workflow["definition"] = workflow_core
		@workflow["fields"] = {
			"dirty" => 0,
			"iteration" => @iteration,
			"load" => @load,
			"case_name" => @case_name,
			"output" => @output, 
		}
	end

	def run
		ret = "timeout"
		start_t= Time.now
		# send workflows iteratively
		@iteration.times do |j|
			@workflow['fields']['iteration'] = j + 1
			timer = 0
			
			# send many workflows as "load" number
			@load.times do |i|
				$queue.publish(@workflow.to_json)
				puts "Request #{i+1}"
			end
			puts "-----------waiting------------"

			# waiting for finish(flag from participant pilot)
			while true
				if not File.exists?(@output+"/iteration_finish")
					sleep 1
					timer = timer + 1
					puts "waiting time: #{timer}"
					if timer > @timeout
						puts "Error: time out"
						ret = "timeout"
						return ret
					end
				else
					ret = "finish"
					File.unlink(@output + "/iteration_finish")
					break
				end
			end
		end
		end_t = Time.now

		# get cpu/dsk/mem load from atop data
		atop_data = $output + "/atop.raw"
		start_t_strf = start_t.strftime("%H:%M")
		end_t_strf = end_t.strftime("%H:%M")
		cmd = "scripts/analyze_load.sh -r #{atop_data} -b #{start_t_strf} -e #{end_t_strf} -o #{@output}"
		if not system(cmd)
			puts "ERROR: failed to get cpu/dsk/mem load data! please run it manually!"
		end
		return ret
	end
end


