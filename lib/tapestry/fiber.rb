
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
      if self != Fiber.current
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
    # Queues something to run in time seconds
    #
    def self.sleep(time)
      t = Coolio::TimerWatcher.new(time, false)
      f = Fiber.current.tapestry_fiber

      t.on_timer do
        t.detach #One-shot…

        f.send :unpark!
      end
      t.attach(Tapestry.ev_loop)
      Fiber.park
    end
    
    
    protected
    
    def check_interrupt
      if i = @interrupt
        @interrupt = nil
        raise i
      end
    end
    
    #
    # Compliment to Fiber#park, resumes the Fiber if it is parked
    #
    def unpark!(reason = nil)
      r = Tapestry.waitqueue[self]
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
      #
      # Pauses the current fiber until woken by an event. NOTE: it is possible to
      # have spurious wakeups. Upon resume, this method may throw an exception if
      # another Fiber called Tapestry::Fiber#raise on this one. 
      #
      def park(timeout = 0, &block)
        f = Fiber.current
        t = f.tapestry_fiber

        t.send :check_interrupt

        Tapestry.waitqueue[t] = f
        Tapestry::LOOP_FIBER.transfer
        Tapestry.waitqueue.delete t
        
        #Upon resume, raise exception if set
        t.send :check_interrupt
      end
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
