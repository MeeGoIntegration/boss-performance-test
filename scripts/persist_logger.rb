#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote

    INTERESTING_ACTIONS = ["launch", "terminated", "dispatch", "receive"]

    #
    # A helper logger for quickstart examples.
    #
    class PersistLogger
        @@it = 0
        @@my_count = -1
        @@process_count = 0
        @@start_time = Time.now
        @@end_time = Time.now

        def initialize (*opts)
            context, out = opts 
            out = "./" if out.nil?
            @out = out 
            puts "output for logger is: #{@out}"
            @context = context
            @context.worker.subscribe(:all, self) if @context.worker
            @msgs_h = Hash.new
        end

        def notify (msg)

            #puts "+++++++++++++++++notify+++++++++++++++++++"
            #p msg

            if msg["action"] == "launch"
                #puts "#{Thread.list.size} ",
                @@my_count = @@my_count + 1
                @@process_count = @@process_count + 1
                if @@my_count == 1
                    @@start_time = Time.now
                    @@it += 1
                    puts "Iteration #{@@it}: start Time: #{@@start_time} | #{@@start_time - @@end_time}"
                    my_file = File.new("#{@out}/LOG",'a')
                    my_file.write("-------- Iteration #{@@it} --------\n")
                    my_file.write(@@start_time)
                    #my_file.write(" | ")
                    #my_file.write(@@start_time - @@end_time)
                    my_file.write("\n")
                    my_file.close
                end
            end

            #return unless msg["action"] == "terminated"
            if msg["action"] == "terminated"
                #puts "#{Thread.list.size} ",
                @@my_count = @@my_count - 1
                if @@my_count == 0
                    @@end_time = Time.now
                    #@@my_count == -1
                    puts "------------------------------"
                    p @@start_time
                    puts "#{@@end_time} | #{@@end_time-@@start_time}"
                    p @@process_count
                    my_file = File.new("#{@out}/LOG", 'a')
                    my_file.write(@@end_time)
                    my_file.write("\n")
                    my_file.write("total workflows: #{@@process_count}")
                    my_file.write("\n")
                    my_file.write("iteration duration: #{@@end_time-@@start_time}")
                    my_file.write("\n")
                    my_file.close
                    #@channels = AMQP::Client.channels()
                    #p @channels
                    #channels.each{|k,v| p k; p v} if channels
                    #puts "CHANNEL" if @channels

                    File.open("#{@out}/load_over", 'w')
                    puts "------------------------------"
                    puts "Thread count: #{Thread.list.size}"
                    #puts "Thread list: #{Thread.list}"
                end
            end
        end
    end
end
