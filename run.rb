#!/usr/bin/env ruby

class Runtime
  def initialize(io)
    membase = io.read.unpack('S<*')
    @memory = membase + [0] * (1<<15 - membase.size)
    @reg = [0] * 8
    @stack = []
    @pc = 0
    @halt = false
  end

  def shift
    v = @memory[@pc]
    @pc += 1
    return v
  end

  REGBASE = 1 << 15
  MOD = 1 << 15

  def read
    v = shift
    if v < REGBASE
      return v
    elsif v - REGBASE < @reg.size
      return @reg[v - REGBASE]
    else
      raise "Bad immediate #{v}"
    end
  end

  def set(loc, v)
    if loc >= REGBASE && loc - REGBASE < @reg.size
      @reg[loc - REGBASE] = v
    else
      raise "Bad register spec #{loc}"
    end
  end

  def do_inst
    pc = @pc
    opcode = shift
    # puts "opcode #{opcode} at #{pc}"
    case opcode
    when 0
      @halt = true
    when 1
      a, b = shift, read
      set(a, b)
    when 2
      @stack.push(read)
    when 3
      raise "Empty stack" if @stack.empty?
      set(shift, @stack.pop)
    when 4
      a, b, c = shift, read, read
      v = (b == c) ? 1 : 0
      set(a, v)
    when 5
      a, b, c = shift, read, read
      v = (b > c) ? 1 : 0
      set(a, v)
    when 6
      @pc = read
    when 7
      a, b = read, read
      @pc = b if a != 0
    when 8
      a, b = read, read
      @pc = b if a == 0
    when 9
      a, b, c = shift, read, read
      set(a, (b + c) % MOD)
    when 10
      a, b, c = shift, read, read
      set(a, (b * c) % MOD)
    when 11
      a, b, c = shift, read, read
      set(a, b % c)
    when 12
      a, b, c = shift, read, read
      set(a, b & c)
    when 13
      a, b, c = shift, read, read
      set(a, b | c)
    when 14
      a, b = shift, read
      set(a, ~b % (1<<15))
    when 15
      set(shift, @memory[read])
    when 16
      @memory[read] = read
    when 17
      loc = read
      @stack.push(@pc)
      @pc = loc
    when 18
      raise "Empty stack" if @stack.empty?
      @pc = @stack.pop
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
