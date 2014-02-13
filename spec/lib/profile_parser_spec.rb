require 'spec_helper'

describe Rubydora::ProfileParser do
  describe ".canonicalize_date_string" do
    it "should correctly trim trailing zeroes in w3c date lexical representations" do
      test_cases = {
        "2014-02-13T19:44:30.630Z" => "2014-02-13T19:44:30.63Z",
        "2014-02-13T19:44:30.600Z" => "2014-02-13T19:44:30.6Z",
        "2014-02-13T19:44:30.000Z" => "2014-02-13T19:44:30Z",
        "2014-02-13T19:44:30.01Z" => "2014-02-13T19:44:30.01Z",
        "2014-02-13T19:44:30.001Z" => "2014-02-13T19:44:30.001Z",
        "2014-02-13T20:40:43.470Z" => "2014-02-13T20:40:43.47Z"
      }
      test_cases.each do |input, expected|
        actual = Rubydora::ProfileParser.canonicalize_date_string( input)
        actual.should == expected
      end
    end
  end
end