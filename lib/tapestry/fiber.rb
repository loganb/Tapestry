
#
# We need some state on the fiber
# 
class Tapestry::Fiber < ::Fiber
  attr_accessor :ev_loop
  
  def initialize(ev_loop, &block)
    super(&block)
    self.ev_loop = ev_loop
    Tapestry.runqueue << self
  end
  
  #
  # Queues something to run in
  #
  def resume_in(time)
    t = Coolio::TimerWatcher.new(time, false)
    f = self
    t.on_timer do
      Tapestry.runqueue << f
      t.detach #One-shot…
    end
    t.attach(evloop)
  end
  
end

class Fiber
  attr_accessor :parent

  alias_method :orig_resume, :resume
  
  def resume(*args)
    self.parent = Fiber.current
    orig_resume(*args)
  end
  
  def ev_loop
    parent.ev_loop if(parent)
  end

end