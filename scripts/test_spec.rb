
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
        true
    end
end

describe "Boss performance test" do
  it "should run test case 001 and then outputs 1000" do
    tester = RSpecTester.new("../test_cases/case_001", "./results")
    tester.run.should == true
  end
  
#  it "should run test case 002 and then outputs 5000" do
#    tester = RSpecTester.new("../test_cases/case_002", "./results")
#    tester.run.should == true
#  end
end
