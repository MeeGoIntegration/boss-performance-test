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

        def initialize (*opts)

            context, log_path = opts 
            
            log_path = "/tmp/boss_performance_test" if log_path.nil?
            @log_path = log_path 
            if test ?d, @log_path
                # delete all files in @log_path
                File.delete(*Dir[@log_path + "/*"])
            else
                Dir.mkdir(@log_path)
            end
            #lp @log_path

            @context = context
            @context.worker.subscribe(:all, self) if @context.worker
            @msgs_h = Hash.new
        end

        def notify (msg)

            #puts "+++++++++++++++++notify+++++++++++++++++++"
            #p msg

            wfid = msg["wfid"] || (msg["fei"] && msg["fei"]["wfid"])
            #puts "++++++++++++wfid is #{wfid}";

            return unless wfid

            return unless INTERESTING_ACTIONS.include?(msg["action"])

            # cache msg
            @msgs_h[wfid] = Array.new if @msgs_h[wfid].nil?
            @msgs_h[wfid] << msg

            return unless msg["action"] == "terminated"

            # persist msgs to file "wfid.msgs"
            file = @log_path + "/#{wfid}.msgs"

            File.open(file, "w") do |f|
                #puts "+++++++++ write to #{file}"
                Marshal.dump(@msgs_h[wfid], f)
                @msgs_h.delete(wfid)
            end

        end
    end
end
