#!/usr/bin/env ruby

require 'scbi_fastq'

class Array
 def count
	self.length
 end

end

if ARGV.count != 3
  puts "#{$0} FASTQ OUTPUT_NAME SEQ_NAMES_FILE"
  exit
else
  
  fasta = ARGV.shift
  output_name = ARGV.shift
  seqs_file=ARGV.shift

  seqs=[]

  f=File.open(seqs_file).each_line do |line|
  	seqs.push line.strip.chomp
  end
  puts seqs.join(';')
  
	fqr=FastqFile.new(fasta)
	
	output_fastq=FastqFile.new(output_name+'.fastq','w')

	fqr.each do |seq_name,seq_fasta,seq_qual|
  	if seqs.index(seq_name)
  	    output_fastq.write_seq(seq_name,seq_fasta,seq_qual)
  			seqs.delete(seq_name)
  			if seqs.empty?
  			  break
			  end
  	end
  end
  
  output_fastq.close
  fqr.close

end
