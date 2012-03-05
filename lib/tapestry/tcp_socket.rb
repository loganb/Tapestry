require 'socket'

require 'tapestry/ip_socket'

module Tapestry
  ##
  # Mirroring the hierarchy of Ruby's native IO, this is a class for
  # implementing blocking sematics on Socket I/O calls
  #
  #
  class TCPSocket < IPSocket
    def initialize(real_socket)
      raise "not a socket" unless real_socket.is_a? ::TCPSocket
      super(real_socket)
    end
    
    
  end
end

class ::TCPSocket
  def tapestrize
    Tapestry::TCPSocket.new(self)
  end
  
end