
class RSpecTester
    def initialize(casename, output)
        @casename = casename
	@output = output
	Dir.mkdir("#{@output}") if not File::directory?("#{@output}")
    end
   
    def desc_case
        cfg_file = File.open("#{@casename}")
	cfg = eval(cfg_file.read)
	puts "Name: #{cfg['name']}"
	puts "Description: #{cfg['desc']}"
    end
    
    def run
        result = false
        desc_case()
	start_time = Time.now
	system("ruby ./run.rb -c #{@casename} -o #{@output} > /dev/null")
	while true
	    f = File.open("#{@output}/rspec.pipe", 'r+')
            str = f.readline
            if str =~ /^finish/i
                result = true
            end
	    break
	end
	test_time = Time.now - start_time
	puts "Test time: #{test_time}"
	result
    end
end

describe "Boss performance test" do
  Dir.mkdir("./results") if not File::directory?("./results")

  it "should run test case 001 and pass through the test successfully " do
    tester = RSpecTester.new("../test_cases/case_001.config", "./results/case_001")
    tester.run.should == true
  end
  
  #it "should run test case 002 and pass through the test successfully" do
  #  tester = RSpecTester.new("../test_cases/case_002.config", "./results/case_002")
  #  tester.run.should == true
  #end
end
