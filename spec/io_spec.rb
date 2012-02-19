require File.expand_path('../spec_helper', __FILE__)

describe Tapestry::IO do
  
  it "blocks on the read end of a pipe" do
    (rp, wp) = File.pipe

    do_async 1 do
      wp.close
    end
    
    Tapestry.boot! do
      #STDERR.puts("About to wait")
      Tapestry::IO.wait_until_read(rp)
      #STDERR.puts("DONE WAITING")
    end
  end
  
  it "Reads frames out of a pipe" do
    (rp, wp) = File.pipe
    
    do_async 1 do
      wp.write("foo\nbar\nbaz")
      wp.close
    end
    
    Tapestry.boot! do
      io = Tapestry::IO.new(rp)
      
      io.read_line.should == "foo\n"
      io.read_line.should == "bar\n"
      io.read_line.should == "baz"
    end
  end
end