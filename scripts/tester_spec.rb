

class RSpecTester
    def initialize(casename, output)
        @casename = casename
	@output = output
    end
   
    def run
#	exec("ruby ./run.rb -c #{@casename} -o #{@output}")
#	while true
#	    f = File.open("#{@output}/run.pipe", 'r+')
#            str = f.readline
#            if str =~ /^finish/i
#                return true
#	    elsif str =~ /^fail/i
#	        return false
#            end
#	    sleep 10
#	end
        return true
    end
end

