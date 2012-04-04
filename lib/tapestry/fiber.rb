
#
# We need some state on the fiber
# 
module Tapestry
  class StateError < Exception; end
  
  class Fiber < ::Fiber

    def initialize(*args, &block)
      super() do
        begin
          block && block.call(*args)
        rescue Exception => e
          STDERR.puts("Execption in #{Fiber.current}: #{e}\n#{e.backtrace.collect { |l| "  #{l}"}.join("\n")}")
          raise
        end
      end
      Tapestry.runqueue << self
    end

    #
    # Raise an exception in this Fiber. The next time the Fiber is 
    # parked (waiting for I/O, etc), it will immediately resume and this 
    # exception will be raised. If the fiber is already parked, it will be
    # awoken and the exception will be reaised. 
    #
    def raise(*args)
      if self != Fiber.current.tapestry_fiber
        @interrupt = args[0]
        unpark!
      else
        Kernel.raise(*args)
      end
    end

    #
    # A Tapestry fiber is always the root of the fiber resume chain
    #
    def tapestry_fiber
      self
    end
    
    #
    # Queues Fiber to resume in time seconds. If the block is supplied,
    # it should return true if the Fiber should resume or false if it should
    # continue waiting for timeout. It will be passed the value passed to 
    # Fiber#signal
    # 
    #
    def self.sleep(time, &block)
      f = Fiber.current
      t = f.tapestry_fiber

      unless(time == :forever)
        timeout = Coolio::TimerWatcher.new(time, false)
        timeout.on_timer do
          timeout.detach
          #STDERR.puts("SIGNALING #{t}")
          t.signal :timeout
        end
        timeout.attach(Tapestry.ev_loop)
      end
      #STDERR.puts("THE TIMEOUT IS #{timeout}, #{Tapestry.ev_loop}")

      begin
        Tapestry.waitqueue[t] = f
        #STDERR.puts("PARKING #{t}")
        Tapestry::LOOP_FIBER.transfer #This is where we lose control
        #STDERR.puts("RESUMED #{t}")
      
        #Upon resume, raise exception if set
        t.send :check_interrupt

        #return the signal value
        s = t.send :signal?
        if s == :timeout or (block_given? ? yield(s) : true)
          timeout.detach if(timeout && timeout.attached?)
          return s
        end
      end while true
    end

    #
    # Can be called to wake a sleeping Fiber. Used internally, and should not
    # be called by user code
    #
    def signal(value)
      raise ArgumentError, "Signal value be nil" if value.nil?
      unless @signal
        @signal = value
        unpark!
      end
    end
    
    protected
    

    #
    # Raises an exception if an interrupt was raised remotely
    #
    def check_interrupt
      if i = @interrupt
        @interrupt = nil
        @signal = nil
        Kernel.raise i
      end
    end
    
    #
    # Returns the object passed to Fiber#signal if the fiber was signalled, 
    # nil otherwise. The signal is also cleared. 
    #
    def signal?
      if s = @signal
        @signal = nil
        s
      end
    end
    
    #
    # Compliment to Fiber#park, resumes the Fiber if it is parked
    #
    def unpark!(reason = nil)
      r = Tapestry.waitqueue[self]
      Tapestry.waitqueue.delete self
      Tapestry.runqueue << r if r
    end
  end
  
  #
  # Methods that get mixed into ::Fiber. 
  #
  module FiberMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    #
    # Returns the Tapestry::Fiber at the top of the call context. This is usually
    # Fiber.current, but if Fiber#resume has been called into another Fiber, 
    # Fiber.current might not be a ::Fiber instead of a Tapestry::Fiber
    #
    def tapestry_fiber
      parent && parent.tapestry_fiber
    end
    
    module ClassMethods
    end
  end
end

class Fiber
  include Tapestry::FiberMethods
  
  attr_accessor :parent

  alias_method :tapestry_orig_resume, :resume
  
  def resume(*args)
    self.parent = Fiber.current
    tapestry_orig_resume(*args)
  end
  
end
