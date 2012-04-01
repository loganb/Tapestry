require 'fiber'

require 'coolio'

module Tapestry
  LOOP_FIBER = Fiber.current
  LOOP = Coolio::Loop.default
  
  def self.boot!(&block)
    @runqueue = []
    @waitqueue = {}
    
    main_fiber = Tapestry::Fiber.new &block
    begin
      while(!runqueue.empty?)
        #run everything in the queue
        f = runqueue.pop
        #STDERR.puts("Running #{f}, #{runqueue.length}")
        f.transfer() if(f.alive?)
      end
      
      #STDERR.puts("About to run once")
      LOOP.run_once
      #STDERR.puts("Ran once")
      #STDERR.puts("Watchers: #{@ev_loop.watchers.join(',')}")
    end while(LOOP.has_active_watchers? || !runqueue.empty?)
    #STDERR.puts("LOOP DONE!")
  end
  
  class <<self
    #
    # Map of Fibers waiting for an event of some kind. The key is the 
    # Tapestry::Fiber (aka root Fiber), the value is the Fiber to resume
    #
    attr_reader :waitqueue
    
    #
    # An array of Fibers that need to be resumed
    #
    attr_reader :runqueue
  end
end

module Kernel
  alias_method :tapestry_orig_sleep, :sleep
  
  def sleep(*args)
    t = Fiber.current.tapestry_fiber
    if(t)
      Tapestry::Fiber.sleep(*args)
    else
      tapestry_orig_sleep(*args)
    end
  end
end

require 'tapestry/fiber'
require 'tapestry/io'
require 'tapestry/tcp_socket'
require 'tapestry/tcp_server'
