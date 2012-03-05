require 'iobuffer'

class Tapestry::IO
  attr_accessor :io, :read_buf, :write_buf
  
  def initialize(real_io)
    self.io  = real_io
    self.read_buf = IO::Buffer.new(128) #Start with a small buffer
    self.write_buf = IO::Buffer.new(128)
  end
  
  def readline(sep = $/)
    ret = ""

    #STDERR.puts("About to read frame: #{read_buf.size}")
    return ret if(read_buf.readline(sep, ret))
    loop do
      unless read_buf.read_from(io)
        #EOF
        read_buf.readline(sep, ret)
        raise EOFError if(ret == '')
        break
      end
      return ret if(read_buf.readline(sep, ret))
      wait_for_read
    end
    ret
  end
  
  def each_line(sep = $/, &block)
    enum = Enumerator.new { |y| 
      while(true)
        begin
          y.yield(readline(sep))
        rescue EOFError
          break
        end
      end
    }
    if(block_given?)
      enum.each &block
    else
      enum
    end
  end
  
  def read(len = nil, buffer = nil)
    if(len.nil?)
      #read everything until EOF
      buffer = read_buf.read
      while(read_buf.read_from(io))
        buffer << read_buf.read
        wait_for_read
      end
      buffer << read_buf.read
    else
      #Seed buffer variable if it is nil
      tmp = read_buf.read(len)
      if buffer
        #Truncate the supplied buffer if there is one
        buffer.clear 
        buffer << tmp
      else
        buffer = tmp
      end
      len -= buffer.length

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
  end
  
  #
  # Equivalent to ::IO#write_nonblock excpect that it will
  # always return immediately (and report writing the full string)
  #
  def write_nonblock(str)
    write_buf.append(str)
    write_buf.write_to(io)
    drain_write_buffer unless write_buf.empty?
    str.length
  end
  
  def write(str)
    ret = write_nonblock(str)
    write_barrier
    ret
  end
  
  ##
  # Blocks until all bytes have been written out the IO object
  #
  def write_barrier
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
  
  ##
  # Equivalent to ::IO#flush. Tapestry will block until all buffered
  # bytes are written to the unerlying socket
  #
  def flush
    write_watcher.sync
  end
  
  #
  # Blocks until the given Ruby IO object is readable
  #
  # This method is useful if you do not want to use other Tapestry::IO 
  # functionality
  #
  def self.read_wait(io, timeout = 0) 
    w = Coolio::IOWatcher.new(io, :r)
    t = Coolio::TimerWatcher.new(timeout, false) if(timeout > 0)

    w.attach Tapestry::LOOP
    t.attach Tapestry::LOOP
    
    f = Fiber.current
    p = Proc.new do
      #Turn off the read watcher
      w.detach
      #Turn off the timer watcher
      t and t.detach

      Tapestry.runqueue << f
    end
    w.on_readable &p
    t and t.on_timer &p

    Tapestry::LOOP_FIBER.transfer
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

class ::IO
  
  def tapestrize
    Tapestry::IO.new(self)
  end
end