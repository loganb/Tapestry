require 'fiber'

require 'coolio'

module Tapestry
  LOOP_FIBER = Fiber.current
  LOOP = Coolio::Loop.default
  
  def self.boot!(&block)
    @runqueue = []
    
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
    attr_reader :runqueue
  end
end

require 'tapestry/fiber'
require 'tapestry/io'
