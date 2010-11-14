require File.dirname(__FILE__) + '/spec_helper'


describe "BOSS performance test suite" do
	before(:all) do
		Dir.mkdir("./tmp") if not File::directory?("./tmp")
	end

	it "should run test long time case and get finished" do
		options = {
			"case_name" => "long_time",
			"channel" => "multiple",
			"load" => 1000,
			"iteration" => 10000000,
			"iteration_timeout" => 600,
			"workflow" => "scripts/workflows/workflow_simple.config",
		}
		runner = MyRunner.new(options)
		runner.run.should == "finish"
	end
end







