#!/usr/bin/env ruby

require 'json'

if ARGV.count<1 
  puts "Usage: #{$0} [-t] [-j] stats1.json"
  exit -1
end

# print header  
if ARGV[0]=='-t'
	heads=['Plugin name','execution_time (s)']
	puts heads.join("\t")   
	ARGV.shift
end

puts_json=false
if ARGV[0]=='-j'
	puts_json=true
	ARGV.shift
end


ARGV.each do |file_path|
	sample_name = File.basename(File.expand_path(File.join(file_path,'..','..')))

	stats=JSON::parse(File.read(file_path))

	res={}

	begin
		stats.keys.each do |k|
			if stats[k]['execution_time']
				res[k]=stats[k]['execution_time']['total_seconds']
			end
		end
		
	rescue Excepcion => e

	   puts "Error reading #{file_path}"
	end

	if puts_json
		puts JSON::pretty_generate(res)
	else
		total=0
		res.keys.sort.each do |k|
			puts "#{k}\t#{res[k]}"
			total+=res[k]
		end
		puts "-"*20
		puts "TOTAL (plugins):\t#{total}"
	end
end

