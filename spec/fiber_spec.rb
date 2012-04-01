require File.expand_path('../spec_helper', __FILE__)

describe Tapestry do

  it "boots and runs the supplied block" do
    block_ran = false
    Tapestry.boot! do
      block_ran = true
    end
    block_ran.should == true
  end
  
  it "runs two fibers concurrently" do
    
    wake_order = []
    Tapestry.boot! do
      #Setup another fiber to run
      Tapestry::Fiber.new do
        Tapestry::Fiber.sleep 0.05
        2.times do
          wake_order << 2
          Tapestry::Fiber.sleep(0.1)
        end
      end
      
      #Sleep for a little less than the other fiber
      2.times do
        wake_order << 1
        Tapestry::Fiber.sleep(0.1)
      end
    end
    
    wake_order.should == [1,2,1,2]
  end

  it "raises exceptions in other Fibers" do
    class TestException < Exception; end
    
    Tapestry.boot! do
      ex = nil
      
      f = Tapestry::Fiber.new do
        begin
          Tapestry::Fiber.sleep 0.1
        rescue TestException => e
          ex = e
        end
      end
      
      #Sleep just enough to let the other Fiber run
      Tapestry::Fiber.sleep 0.01
      f.raise TestException
      Tapestry::Fiber.sleep 0.01
      
      (ex.is_a? TestException).should == true
    end
  end
  
  it "reports itself as the tapestry fiber" do
    Tapestry.boot! do
      tap_fiber = nil
      fiber = Tapestry::Fiber.new do
        tap_fiber = Fiber.current.tapestry_fiber
      end
      Tapestry::Fiber.sleep 0.01
      
      tap_fiber.should == fiber
    end
  end
  
  it "sleeps properly from a nested (regular) fiber" do
    results = []
    Tapestry.boot! do
      
      f = ::Fiber.new do
        results << 2
        Tapestry::Fiber.sleep(0.01)
        results << 3
      end
      results << 1
      f.resume
      results << 4
    end
    results.should == [1,2,3,4]
  end
end