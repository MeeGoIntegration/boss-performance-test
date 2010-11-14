require File.dirname(__FILE__) + '/spec_helper'


describe "BOSS performance test suite" do

	it "should run test case 001 and get finished" do
		options = {
			"case_name" => "case_001",
			"channel" => "multiple",
			"load" => 5000,
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
			"load" => 10000,
			"iteration" => 1,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
	
	it "should run test case 003 and get finished" do
		options = {
			"case_name" => "case_003",
			"channel" => "multiple",
			"load" => 50000,
			"iteration" => 1,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
	
	it "should run test case 004 and get finished" do
		options = {
			"case_name" => "case_004",
			"channel" => "multiple",
			"load" => 100000,
			"iteration" => 1,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
end







