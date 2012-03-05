
module Tapestry
  ##
  # Mirroring the hierarchy of Ruby's native IO, this is a class for
  # implementing blocking sematics on Socket I/O calls
  #
  #
  class TCPServer < TCPSocket
    def initialize(real_socket)
      raise "not a server socket" unless real_socket.is_a? ::TCPServer
      super(real_socket)
    end
    
    def accept
      begin
        TCPSocket.new(io.accept_nonblock)
      rescue Errno::EWOULDBLOCK => e
        wait_for_read
        retry
      end
    end
  end
end

class ::TCPServer
  def tapestrize
    Tapestry::TCPServer.new(self)
  end
  
end