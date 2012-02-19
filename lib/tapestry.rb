require 'fiber'

require 'coolio'

module Tapestry
  LOOP_FIBER = Fiber.current
  
  def self.boot!(&block)
    @runqueue = []
    @ev_loop = Coolio::Loop.default
    
    main_fiber = Tapestry::Fiber.new @ev_loop, &block
    begin
      while(!runqueue.empty?)
        #run everything in the queue
        f = runqueue.pop
        #STDERR.puts("Running #{f}, #{runqueue.length}")
        f.transfer() if(f.alive?)
      end
      
      #STDERR.puts("About to run once")
      @ev_loop.run_once
      #STDERR.puts("Ran once")
      #STDERR.puts("Watchers: #{@ev_loop.watchers.join(',')}")
    end while(@ev_loop.has_active_watchers? || !runqueue.empty?)
    #STDERR.puts("LOOP DONE!")
  end
  
  class <<self
    attr_reader :runqueue
  end
end

require 'tapestry/fiber'
require 'tapestry/io'
