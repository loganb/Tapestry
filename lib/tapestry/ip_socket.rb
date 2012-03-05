require 'socket'
require 'tapestry/io'

##
# Mirroring the hierarchy of Ruby's native IO, this is a class for
# implementing blocking sematics on Socket I/O calls
#
#
class Tapestry::IPSocket < Tapestry::IO
  def initialize(real_socket)
    raise "not a socket" unless real_socket.is_a? ::IPSocket
    super(real_socket)
  end
  
  def addr(reverse_lookup = nil)
    raise "reverse_lookup not supported" if(reverse_lookup)
    io.addr(reverse_lookup)
  end
  
  def peeraddr(reverse_lookup = nil)
    raise "reverse_lookup not supported" if(reverse_lookup)
    io.peeraddr(reverse_lookup)
  end
end