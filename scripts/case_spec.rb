require File.dirname(__FILE__)+'/spec_helper'

cfg_file = File.open("#{@@output}/test_case.config", 'r')
cfg = eval(cfg_file.read)
case_name = cfg['name']
case_desc = cfg['desc']
cfg_file.close

class CaseTester       
    def initialize(case_name)
        @case_name = case_name
        Dir.mkdir("#{@@output}/#{@case_name}") if not File::directory?("#{@@output}/#{@case_name}")
    end
    
    def run
        result = true
	system("ruby ./run.rb -c #{@@output}/test_case.config -o #{@@output}/#{@case_name} > /dev/null")
	while true
	    f = File.open("#{@@output}/#{@case_name}/rspec.pipe", 'r+')
            str = f.readline
            if str =~ /^finish/i
                result = true
            end
	    break
	end
        puts "------------------------------------------"
	result
    end
end

describe "Boss performance test case" do
  before(:all) do
    #Dir.mkdir("#{output}/#{case_name}") if not File::directory?("#{output}/#{case_name}")
  end

  it "#{case_name} - should #{case_desc}" do
    tester = CaseTester.new(case_name)
    tester.run.should == true
  end  
end
