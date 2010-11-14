require File.dirname(__FILE__) + '/spec_helper'


describe "BOSS performance test suite" do
	before(:all) do
		Dir.mkdir("./tmp") if not File::directory?("./tmp")
	end

	it "should run test case 001 and get finished" do
		options = {
			"case_name" => "case_001",
			"channel" => "multiple",
			"load" => 200,
			"iteration" => 1,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
	
	it "should run test case 002 and get finished" do
		options = {
			"case_name" => "case_002",
			"channel" => "multiple",
			"load" => 50,
			"iteration" => 1,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
end







