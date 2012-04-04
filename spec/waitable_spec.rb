require File.expand_path('../spec_helper', __FILE__)

describe Tapestry::Waitable do
  #Make a class with a single signal and instantiate it
  class TestClass
    include Tapestry::Waitable
    
    signal_on :test_it
  end

  it "waits for a signal" do
    results = []
    
    Tapestry.boot! do
      obj = TestClass.new
      
      Tapestry::Fiber.new do
        results << 1
        obj.wait_for_test_it
        results << 3
      end
      
      Tapestry::Fiber.sleep(0.01)
      results << 2
      obj.signal_test_it
    end
    
    results.should == [1,2,3]
  end
  
  it "times out waiting for a signal" do
    results = []
    
    Tapestry.boot! do
      obj = TestClass.new

      Tapestry::Fiber.new do
        
      end
      
      Tapestry::Fiber.sleep 0.01
    end
  end

end