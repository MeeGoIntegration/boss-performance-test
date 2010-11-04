require File.dirname(__FILE__) + '/spec_helper'

class SuiteTester
    def initialize(suitename)
        @suitename = suitename
    end
   
    def run
        f = File.open("#{@suitename}", 'r')
        cases = eval(f.read)
        cases.each { |k, v|
            casefile = File.new("#{@@output}/test_case.config", 'w');
            casefile.write(v.inspect);
            casefile.close;
            system("spec --format nested ./case_spec.rb")
        }
        f.close
    end
end

describe "Boss performance test - suite" do
  it "should run all test cases included in specified config file" do
    suites = Dir.glob("#{@@suite}")
    suites.each { |suitefile|
        tester = SuiteTester.new(suitefile)
        tester.run;
        puts "**********************************************"
    }
  end

  after(:all) do
      File.unlink("#{@@output}/test_case.config")
  end
end
