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
        Fiber.current.resume_in(0.2)
        wake_order << 2
      end
      
      #Sleep for a little less than the other fiber
      Fiber.current.resume_in(0.1)
      wake_order << 1
    end
    
    wake_order.should == [1,2]
  end

end