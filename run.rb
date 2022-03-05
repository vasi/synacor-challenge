#!/usr/bin/env ruby
require 'yaml'

class Runtime
  def initialize(io, inputs)
    membase = io.read.unpack('S<*')
    @memory = membase + [0] * (1<<15 - membase.size)
    @reg = [0] * 8
    @stack = []
    @pc = 0
    @halt = false
    @debug = false

    @inbuf = []
    @inputs = inputs
    @curline = ""
    @outputs = []
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
      if v - REGBASE == 7
        # puts "WHOA MAGIC EIGHTH REGISTER"
      end
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

  def getc
    if @inbuf.empty?
      input = nil
      loop do
        input = if @inputs.empty?
          gets.chomp
        else
          puts @inputs.first
          @inputs.shift
        end

        if input == 'debug'
          @debug = !@debug
        elsif md = /^set (\d+) (\d+)$/.match(input)
          @reg[md[1].to_i] = md[2].to_i
        else
          break
        end
      end
      @inbuf = (input + "\n").chars.map(&:ord)
    end
    return @inbuf.shift
  end

  def putc(c)
    $stdout.putc(c)
    if c.chr == "\n"
      @outputs << @curline
      @curline = ""

      # @debug = true if /billion/.match(@outputs[-2])
    else
      @curline += c.chr
    end
  end

  OPCODES = [
    ["halt", 0],
    ["set", 2],
    ["push", 1],
    ["pop", 1],
    ["eq", 3],
    ["gt", 3],
    ["jmp", 1],
    ["jt", 2],
    ["jf", 2],
    ["add", 3],
    ["mult", 3],
    ["mod", 3],
    ["and", 3],
    ["or", 3],
    ["not", 2],
    ["rmem", 2],
    ["wmem", 2],
    ["call", 1],
    ["ret", 0],
    ["out", 1],
    ["in", 1],
    ["noop", 0],
  ]

  def disasm_helper(loc)
    opcode = @memory[loc]
    inst, argc = *OPCODES[opcode]
    args = (0...argc).map do |i|
      a = @memory[loc + i + 1]
      a >= REGBASE ? "r#{a-REGBASE}" : a.to_s
    end
    [inst, args, "#{loc.to_s.ljust(5)}  #{inst.ljust(4)} #{args.join(' ')}"]
  end
  
  def disasm(range)
    loc = range.first
    out = []
    while range.include?(loc)
      inst, args, dis = disasm_helper(loc)
      out << dis
      loc += args.size + 1
    end
    out
  end

  def disasm1(loc)
    disasm_helper(loc).last
  end

  def inspect
    dis = disasm1(@pc).ljust(20)
    regs = @reg.map {|r| r.to_s.ljust(5) }.join(' ')
    depth = @stack.size
    "#{dis}  r=[#{regs}]  #st=#{depth}"
  end

  def do_inst
    puts inspect if @debug
    pc = @pc
    opcode = shift
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
      putc(read)
    when 20
      set(shift, getc)
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
world = YAML.load(open(ARGV.shift))
moves = world['Moves']

runtime = Runtime.new(open(file), moves)
#puts runtime.disasm(6027..6067).join("\n")
runtime.run
