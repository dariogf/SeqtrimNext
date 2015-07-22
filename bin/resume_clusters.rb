#!/usr/bin/env ruby

require 'json'

if ARGV.count != 2
  puts "#{$0} cluster.fasta.clstr COUNT"
  exit
end

path=ARGV.shift
list_max=ARGV.shift.to_i

# puts path

h={}

last_line = ''

f=File.open(path)

f.each do |line|
  if line =~ />Cluster/
      if !last_line.empty?
        if last_line =~ /^([\d]+)\s[^>]*>([^\s]*)\.\.\.\s/
          # puts $1
          h[$2]=$1.to_i+1
        end
      end
  end
  
  last_line=line
  
end

f.close


# puts "30 most repeated sequences:"
list_max.times do
  ma=h.max_by{|k,v| v}
  if ma
    puts ma.join(' => ')
    h.delete(ma[0])
  end
end


# puts h.sort.to_json