#!/usr/bin/env ruby

require 'scbi_fasta'

# GOOD_QUAL=50
# BAD_QUAL=10
# DOWN_CASE=('a'..'z')


class Array
 def count
	self.length
 end

end

if ARGV.count < 4
  puts "#{$0} FASTA QUAL OUTPUT_NAME SEQ_NAMES_FILE"
  exit
else
  
  fasta = ARGV.shift
  qual = ARGV.shift
  output_name = ARGV.shift
  seqs_file=ARGV.shift

  seqs=[]

  f=File.open(seqs_file).each_line do |line|
  	seqs.push line.strip.chomp
  end
  # puts seqs.join(';')
  
	fqr=FastaQualFile.new(fasta,qual)
	
	output_fasta=File.new(output_name+'.fasta','a')
	output_qual=File.new(output_name+'.fasta.qual','a')

	fqr.each do |seq_name,seq_fasta,seq_qual|
  	if seqs.index(seq_name)
  	    output_fasta.puts ">#{seq_name}"
  			output_fasta.puts seq_fasta
  	    output_qual.puts ">#{seq_name}"
  			output_qual.puts seq_qual
  			seqs.delete(seq_name)
  			if seqs.empty?
  			  break
			  end
  	end
  end
  
  output_qual.close
  output_fasta.close
  fqr.close

end
