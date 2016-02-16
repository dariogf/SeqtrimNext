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

	begin
		res << sample_name
		res << stats['sequences']['count']['input_count'] 
		res << stats['sequences']['count']['output_seqs_paired'] 
		res << stats['sequences']['count']['output_seqs'] 
		res << stats['sequences']['count']['rejected'] 
		res << sprintf('%.2f',(stats['sequences']['count']['rejected'].to_f/(stats['sequences']['count']['output_seqs_paired'].to_i+stats['sequences']['count']['output_seqs'].to_i).to_f)*100) 
		
	rescue Excepcion => e

	   puts "Error reading #{file_path}"
	end

	puts res.join("\t")

end

