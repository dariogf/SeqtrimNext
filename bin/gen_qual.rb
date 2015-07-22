#!/usr/bin/env ruby

require 'scbi_fasta'

GOOD_QUAL=50
BAD_QUAL=10
DOWN_CASE=('a'..'z')


class Array
 def count
	self.length
 end

end

if ARGV.count != 2
  puts "Programa ENTRADA SALIDA" 
  exit
else
  puts ARGV[0]
  puts ARGV[1]
  
	fqr=FastaQualFile.new(ARGV[0])
	
	f = File.new(ARGV[1],'w+')

	fqr.each do |seq_name,seq_fasta,seq_qual|
    f.puts ">#{seq_name}"
	res =[]
	seq_fasta.each_char do |c|
		if DOWN_CASE.include?(c)
			res << BAD_QUAL
		else
			res << GOOD_QUAL
		end
	end

	f.puts res.join(' ')
#f.puts "50 "*seq_fasta.length
  end
  
  f.close
  fqr.close

end
