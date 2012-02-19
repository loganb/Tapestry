require 'iobuffer'

class Tapestry::IO
  attr_accessor :io, :buf
  
  def initialize(real_io)
    self.io  = real_io
    self.buf = IO::Buffer.new
  end
  
  def read_line(sep = "\n")
    raise if sep.length > 1
    ret = ""

    #STDERR.puts("About to read frame: #{buf.size}")
    return ret if(buf.read_frame(ret, sep.ord))
    loop do
      unless buf.read_from(io)
        #EOF
        buf.read_frame(ret, sep.ord)
        break
      end
      wait_until_read
    end
    ret
  end
  
  
  protected
  
  def wait_until_read()
    self.class.wait_until_read(io)
  end
  
  #
  # Halts the current fiber until the supplied io is readable
  #
  def self.wait_until_read(io)
    w = Coolio::IOWatcher.new(io, :r)
    f = Fiber.current
    
    w.on_readable do
      #Tapestry.runqueue << f
      f.transfer()
      w.detach
    end
    
    w.attach(f.ev_loop)
    #STDERR.puts("going to the ev fiber")
    Tapestry::LOOP_FIBER.transfer()
    #STDERR.puts("Returned from ev fiber")
  end
end