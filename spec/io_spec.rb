require File.expand_path('../spec_helper', __FILE__)

describe Tapestry::IO do
  
  it "blocks on the read end of a pipe" do
    (rp, wp) = File.pipe

    do_async 0.1 do
      wp.close
    end
    
    Tapestry.boot! do
      #STDERR.puts("About to wait")
      io = Tapestry::IO.new(rp)
      io.wait_for_read()
      #STDERR.puts("DONE WAITING")
      io.close
    end
  end
  
  it "blocks with a timeout (static method)" do
    (rp, wp) = File.pipe
    
    s = e = 0
    Tapestry.boot! do
      s = Time.now
      Tapestry::IO.read_wait(rp, 0.1)
      e = Time.now
    end
    
    (e - s).should > 0.1
  end
  
  it "reads frames out of a pipe (readline)" do
    (rp, wp) = File.pipe
    
    do_async 0.1 do
      wp.write("foo\nbar\nbaz")
      wp.close
    end
    
    Tapestry.boot! do
      io = Tapestry::IO.new(rp)
      
      io.readline.should == "foo\n"
      io.readline.should == "bar\n"
      io.readline.should == "baz"
      io.close
    end
  end
  
  it "emulates IO::read()" do
    (rp, wp) = File.pipe
    
    do_async 0 do
      wp.write("Fooz")
    end
    
    Tapestry.boot! do
      io = Tapestry::IO.new(rp)

      io.read(2).should == "Fo"
      io.read(2, "bar").should == "oz"
      io.close
    end
  end
  
  it "emulates IO::readline" do
    (rp, wp) = File.pipe
    
    do_async 0 do
      wp.write("line1\nline2\nline3")
      wp.close
    end
    
    Tapestry.boot! do
      io = Tapestry::IO.new(rp)
      
      io.readline.should == "line1\n"
      io.readline.should == "line2\n"
      io.readline.should == "line3"
      
      lambda {
        io.readline
      }.should raise_error(EOFError)
    end
  end
  
  it "writes out data" do
    (rp, wp) = File.pipe
    data_len     = nil
    correct_data = false
    
    th = do_async 0.1 do
      data = rp.read
      data_len = data.length
      correct_data   = true if data == ('a' * 1000 + 'x' * 8000)
    end
    
    Tapestry.boot! do
      io = Tapestry::IO.new(wp)
      
      io.write('a' * 1000 + 'x' * 8000)
      io.close
    end
    th.join
    data_len.should == 9000
    correct_data.should == true
  end
end