#!/usr/bin/env ruby

class Runtime
  def initialize(io)
    membase = io.read.unpack('S<*')
    @memory = membase + [0] * (1<<15 - membase.size)
    @registers = [0] * 8
    @stack = []
    @pc = 0
    @halt = false
  end

  def shift
    v = @memory[@pc]
    @pc += 1
    return v
  end

  REGBASE = 32768
  def read
    v = shift
    if v < REGBASE
      return v
    elsif v - REGBASE <= @registers.size
      return @registers[v - REGBASE]
    else
      raise "Bad immediate #{v}"
    end
  end

  def do_inst
    pc = @pc
    opcode = shift
    case opcode
    when 0
      @halt = true
    when 19
      $stdout.putc(read)
    when 21
      # noop
    else
      raise "Unknown opcode #{opcode} at #{pc}"      
    end
  end

  def run
    until @halt
      do_inst
    end
  end
end

file = ARGV.shift
runtime = Runtime.new(open(file))
runtime.run
