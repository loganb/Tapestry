require 'fiber'

b = nil
a = Fiber.new do |main|
  b = Fiber.new do
    STDERR.puts("IN B")
  end

  STDERR.puts("IN A")
  b.transfer()
  STDERR.puts("BACK IN A")
  STDERR.puts("A DONE")
end


a.transfer(Fiber.current)
STDERR.puts("DONE")