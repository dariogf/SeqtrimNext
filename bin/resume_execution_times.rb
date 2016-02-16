#!/usr/bin/env ruby

require 'json'

if ARGV.count<1 
  puts "Usage: #{$0} [-t] [-j] [-h] stats1.json"
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

time_divider=1
# print header  
if ARGV[0]=='-h'
	time_divider=3600
	puts "Times are in hours"
	ARGV.shift
end



ARGV.each do |file_path|
	sample_name = File.basename(File.expand_path(File.join(file_path,'..','..')))

	stats=JSON::parse(File.read(file_path))

	res={}
	
	total=0
		

	begin
		stats.keys.each do |k|
			if stats[k]['execution_time']
				res[k]=stats[k]['execution_time']['total_seconds'].to_f/time_divider
				total+=res[k]
			end
		end

		res["TOTAL_plugins"]=total
		
	rescue Excepcion => e

	   puts "Error reading #{file_path}"
	end

	if stats['scbi_mapreduce']
		res['TOTAL_workers']=stats['scbi_mapreduce']['connected_workers']
		res['TOTAL_read']=stats['scbi_mapreduce']['total_read_time']/time_divider
		res['TOTAL_write']=stats['scbi_mapreduce']['total_write_time']/time_divider
		res['TOTAL_manager_idle']=stats['scbi_mapreduce']['total_manager_idle_time']/time_divider
		res['TOTAL_execution']=stats['scbi_mapreduce']['total_seconds']/time_divider
	end

	if puts_json
		puts JSON::pretty_generate(res)
	else
		res.keys.sort.each do |k|
			puts "#{k}\t#{res[k]}"
		end
	end

end

