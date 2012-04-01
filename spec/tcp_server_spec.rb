require File.expand_path('../spec_helper', __FILE__)

require 'socket'

describe Tapestry::TCPServer do
  
  it "Accepts connections on a socket" do
    
    
    do_async 0.2 do
      s = TCPSocket.new('localhost', 31337)
      s.close
    end
    
    ordering = []
    Tapestry.boot! do
      
      Tapestry::Fiber.new do
        Tapestry::Fiber.sleep 0.1
        ordering << :sleep_ended
      end
      
      ordering << :listen_begin
      s = Tapestry::TCPServer.new(::TCPServer.new(31337))
      s.accept
      ordering << :socket_accepted
      s.close
    end
    
    ordering.should == [:listen_begin, :sleep_ended, :socket_accepted]
  end
end