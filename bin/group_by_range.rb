#!/usr/bin/env ruby


if ARGV.count != 1
  puts "#{$0} FASTA "
  exit
end


  
file = ARGV.shift

f=File.open(file)

f.each_line do |line|
  puts line
end
