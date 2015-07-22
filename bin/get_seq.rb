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

if ARGV.count < 3
  puts "#{$0} FASTA QUAL SEQ_NAME [f|q|fq]"
  exit
else
  
	fqr=FastaQualFile.new(ARGV[0],ARGV[1])
    get_type = 'fq'
	if ARGV.count == 4
		get_type=ARGV[3]
	end

	fqr.each do |seq_name,seq_fasta,seq_qual|
	if seq_name == ARGV[2]
		if get_type.index('f')
	    	puts ">#{seq_name}"
			puts seq_fasta
		end

		if get_type.index('q')
	    	puts ">#{seq_name}"
			puts seq_qual
		end
		break
	end

  end
  
  fqr.close

end
