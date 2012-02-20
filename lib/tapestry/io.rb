require 'iobuffer'

class Tapestry::IO
  attr_accessor :io, :read_buf, :write_buf
  
  def initialize(real_io)
    self.io  = real_io
    self.read_buf = IO::Buffer.new(128) #Start with a small buffer
    self.write_buf = IO::Buffer.new(128)
  end
  
  def readline(sep = $/)
    raise if sep.length > 1
    ret = ""

    #STDERR.puts("About to read frame: #{read_buf.size}")
    return ret if(read_buf.read_frame(ret, sep.ord))
    loop do
      unless read_buf.read_from(io)
        #EOF
        read_buf.read_frame(ret, sep.ord)
        break
      end
      wait_for_read
    end
    ret
  end
  
  def read(len, buffer = nil)
    #Truncate the supplied buffer if there is one
    buffer.clear if buffer
    #First drain as much as possible out of the io buffer
    tmp = read_buf.read(len)
    buffer = buffer ? buffer << tmp : tmp
    len -= tmp.length
    return buffer if len == 0
    
    #now read from the file handle until full
    begin 
      read_buf.read_from(io)
      tmp = read_buf.read(len)
      buffer << tmp
      len -= tmp.length
    end while(len > 0 && wait_for_read)
    buffer
  end
  
  def write_async(str)
    write_buf.append(str)
    write_buf.write_to(io)
    drain_write_buffer unless write_buf.empty?
  end
  
  def write(str)
    write_async(str)
    wait_until_write
  end
  
  ##
  # Blocks until all bytes have been written out the IO object
  #
  def wait_until_write
    write_watcher.sync
  end
  
  def close
    read_watcher.detach
    write_watcher.detach
    io.close
  end
  
  def wait_for_read
    read_watcher.wait_on
    true
  end
  
  protected
  
  #
  # Enables the write listener and continuously writes bytes our the io object
  # from the write_buf until it is empty. Then, it disables the write listener
  #
  def drain_write_buffer
    write_watcher.enable
  end
  
  def read_watcher
    @read_watcher ||= ReadWatcher.new(self)
  end
  
  def write_watcher
    @write_watcher ||= WriteWatcher.new(self)
  end
  
  # :nodoc:
  #
  # A little helper for read watching to make IOWatcher more sane
  #
  class ReadWatcher < Coolio::IOWatcher
    attr_accessor :blocking_fiber
    
    def initialize(tio)
      super(tio.io, :r)
      attach Tapestry::LOOP
      disable
    end
    
    def wait_on
      f = Fiber.current
      
      self.blocking_fiber = f
      enabled? || enable
      
      Tapestry::LOOP_FIBER.transfer
      
      disable
    end
    
    def on_readable
      blocking_fiber.transfer
    end
    
    def detach
      attached? && super
    end
  end
  
  class WriteWatcher < Coolio::IOWatcher
    attr_reader :tapestry_io
    attr_accessor :blocking_fiber
    
    def initialize(tio)
      super(tio.io, :w)
      attach(Tapestry::LOOP)
      disable
      @tapestry_io = tio
    end
    
    def on_writable
      buf = tapestry_io.write_buf
      buf.write_to(tapestry_io.io)
      if(buf.empty?)
        self.disable
      
        if(f = blocking_fiber)
          self.blocking_fiber = nil
          f.transfer
        end
      end
    end
    
    def enable
      enabled? or super
    end
    
    def sync
      return unless enabled?
      raise "Double waiting error" if(blocking_fiber)
      self.blocking_fiber = Fiber.current
      Tapestry::LOOP_FIBER.transfer
    end
  end
end