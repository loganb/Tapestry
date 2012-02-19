require File.expand_path('../spec_helper', __FILE__)

describe Tapestry do

  it "boots and runs the supplied block" do
    block_ran = false
    Tapestry.boot! do
      block_ran = true
      Fiber.current.ev_loop.nil?.should == false
    end
    block_ran.should == true
  end

end