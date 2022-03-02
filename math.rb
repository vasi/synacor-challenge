#!/usr/bin/env ruby

coins = [2, 3, 5, 7, 9]

def eval(order)
  a, b, c, d, e = *order
  a + b * c**2 + d**3 - e
end

coins.permutation.each do |order|
  if eval(order) == 399
    puts order.join(' ')
    break
  end
end
