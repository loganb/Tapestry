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
        Fiber.current.sleep 0.05
        2.times do
          wake_order << 2
          Fiber.current.sleep(0.1)
        end
      end
      
      #Sleep for a little less than the other fiber
      2.times do
        wake_order << 1
        Fiber.current.sleep(0.1)
      end
    end
    
    wake_order.should == [1,2,1,2]
  end

end