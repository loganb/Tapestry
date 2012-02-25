
#
# We need some state on the fiber
# 
class Tapestry::Fiber < ::Fiber
  
  def initialize(&block)
    super() do
      begin
        block && block.call
      rescue Exception => e
        STDERR.puts("Execption in #{Fiber.current}: #{e}\n#{e.backtrace.collect { |l| "  #{l}"}.join("\n")}")
        raise
      end
    end
    Tapestry.runqueue << self
  end
  
  #
  # Queues something to run in time seconds
  #
  def sleep(time)
    t = Coolio::TimerWatcher.new(time, false)
    f = self
    t.on_timer do
      Tapestry.runqueue << f
      t.detach #One-shot…
    end
    t.attach(Tapestry::LOOP)
    Tapestry::LOOP_FIBER.transfer
  end
  
end

class Fiber
  attr_accessor :parent

  alias_method :orig_resume, :resume
  
  def resume(*args)
    self.parent = Fiber.current
    orig_resume(*args)
  end
end