module Ruote

    #
    # A logger for boss performance testing  
    #
    class PersistLogger

        def initialize (*opts)
            context, out = opts 
            out = "./" if out.nil?
            @out = out 
            #puts "output for logger is: #{@out}"
            @context = context
            @context.worker.subscribe(:all, self) if @context.worker
            @msgs_h = Hash.new

            @iteration = 0
            @launch_cnt = 0
            @terminated_cnt = 0
            @load = 0
            @start_t = Time.now
            @end_t = Time.now
        end

        def reset_iteration
            @iteration = 0
            @launch_cnt = 0
            @terminated_cnt = 0
            @load = 0
            @start_t = Time.now
            @end_t = Time.now
        end

        def inspect_counters
            puts "iteration: #{@iteration}"
            puts "launch_cnt: #{@launch_cnt}"
            puts "terminated_cnt: #{@terminated_cnt}"
            puts "load: #{@load}"
        end

        def notify (msg)
            #puts "+++++++++++++++++notify+++++++++++++++++++"
            #p msg
            #back = "\r"

            # deal with "launch" message
            if msg["action"] == "launch"
                # check if coming "launch" message is not for current iteration 
                tmp_iteration = msg["workitem"]["fields"]["iteration"]
                if @iteration != tmp_iteration
                    if @launch_cnt != 0 || @terminated_cnt != 0
                        puts "ERROR: launch message for iteration #{tmp_iteration} coming but currently we are handling iteration #{@iteration}"
                        return
                    else
                        @iteration = tmp_iteration
                        @load = msg["workitem"]["fields"]["load"]
                        puts "\n---------- Iteration #{@iteration} -----------"
                        @start_t = Time.now
                        puts "start time:\t#{@start_t}"
                    end
                end
                @launch_cnt = @launch_cnt + 1
                #if @launch_cnt == 1
                #    print "dealing with workflow #{@launch_cnt}..."
                #else
                #    print "#{back}dealing with workflow #{@launch_cnt}..."
                #end
            end

            # deal with "terminated" message
            if msg["action"] == "terminated"
                # check if coming "terminated" message is not for current iteration 
                tmp_iteration = msg["workitem"]["fields"]["iteration"]
                if @iteration != tmp_iteration
                    puts "ERROR: terminated message for iteration #{tmp_iteration} coming but currently we are handling iteration #{@iteration}"
                    return
                end

                @terminated_cnt = @terminated_cnt + 1

                if @terminated_cnt == @load
                    @end_t = Time.now
                    puts "end time:\t#{@end_t}"
                    duration = @end_t - @start_t
                    printf("duration:\t%.2f seconds\n", duration)
                    printf("rate:\t\t%.2f workflows/second\n", (@load/duration))
                    puts "---------------------------------------\n"
                    reset_iteration()
                    #puts "#{Thread.list.size} ",
                    File.open("#{@out}/iteration_finish", 'w')
                end
            end
        end
    end
end
