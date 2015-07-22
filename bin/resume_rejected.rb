#!/usr/bin/env ruby

if ARGV.count!=1
  puts "You must specify a file with seqtrim's rejected sequences"
	puts "Usage $0 rejected_seqtrim_file";
	exit(-1);
end


rejected_file=ARGV.shift

if !File.exists?(rejected_file)
  puts "File #{rejected_file} doesn't exists"
	puts "Usage $0 rejected_seqtrim_file";
	exit(-1);
end


res={}

File.open(rejected_file).each do |line|
  
  cols=line.split(' ')
  cols.shift
  
  res[cols.join(' ')] = 0 if !res[cols.join(' ')]
  res[cols.join(' ')] += 1
end

res.each do |k,v|
  puts "#{v} #{k}"
end
