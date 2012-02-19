$LOAD_PATH.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'tapestry'


def do_async(delay, &block)
  Thread.new do
    sleep delay
    block.call
  end
end