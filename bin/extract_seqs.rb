#!/usr/bin/env ruby

require 'scbi_fastq'

class Array
 def count
	self.length
 end

end

if ARGV.count < 3
  puts "#{$0} FASTA OUTPUT_NAME SEQ_NAME_FILE [MORE_SEQ_NAMES]"
  exit
else
  
  fasta = ARGV.shift
  qual = ARGV.shift
  output_name = ARGV.shift
  seqs=ARGV
  puts seqs.join(';')
  
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
