#!/usr/bin/env ruby

require 'json'

if ARGV.count<1 
  puts "Usage: #{$0} stats1.json [stats2.json stats3.json,...]"
  exit -1
end

# print header  
if ARGV[0]=='-t'
	heads=['sample_name','input_count','sequence_count_paired','sequence_count_single','rejected','rejected_percent']
	puts heads.join("\t")
	ARGV.shift
end


ARGV.each do |file_path|
	sample_name = File.basename(File.expand_path(File.join(file_path,'..','..')))

	stats=JSON::parse(File.read(file_path))

	res=[]
	cont=stats['PluginContaminants']['contaminants_ids']

	limit=60	
	cont.keys.sort{|c1,c2| cont[c2].to_i <=> cont[c1].to_i}.each do |k|
		puts "#{k} => #{cont[k]}"

		limit = limit -1
		break if limit==0
	end

end
