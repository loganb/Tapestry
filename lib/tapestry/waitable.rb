#
# Waitable includes methods and attributes to enable a Fiber
# to block on the object
#
#
module Tapestry::Waitable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    #
    # Defines the methods:
    #   * wait_for_sym
    #   * on_sym
    #   * signal_sym
    #
    # If a block is supplied, it is called in the (context of the instance
    # object) whenever wait_for_sym or on_sym is called and can be used to 
    # arm the signal or otherwise set it up to fire. 
    #
    # Example: 
    #
    # TBD
    #
    def signal_on(sym, &block)
      sig_var = "@_#{sym}_wait_set".to_sym

      add_to_set = ->(f) do
        wait_set = instance_variable_get sig_var
        #The common case is that there's only one waiter, so we only
        #create the Array if there's more than one
        if(wait_set.is_a? Array)
          wait_set << f
        else
          if wait_set.nil?
            #No waiters, we're the first
            v = f
          else
            #One waiter already, promote to array
            v = [wait_set, f]
          end
          instance_variable_set sig_var, v
        end
      end
      
      define_method "wait_for_#{sym}".to_sym, ->(timeout = :forever) do
        instance_exec Fiber.current.tapestry_fiber, &add_to_set
        
        Fiber.sleep(timeout) == sym
      end
      
      define_method "on_#{sym}" do |&block|
        instance_exec block, &add_to_set
      end
      
      exec_cb = lambda do |cb|
        if cb.is_a? Proc
          cb.call
        else #Its a Fiber
          cb.signal :sym
        end
      end
      
      define_method "signal_#{sym}" do
        wait_set = instance_variable_get sig_var
        
        if wait_set.nil?
          false
        else
          if wait_set.is_a? Array
            wait_set.each &exec_cb
          else
            exec_cb.call wait_set
          end
          true
        end
      end
    end
  end
  
  protected
end