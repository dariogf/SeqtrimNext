#!/usr/bin/env ruby

require 'scbi_fasta'

if ARGV.count!=3
	puts "Usage: #{$0} fasta qual output_base_name"
	exit
end

fasta_path = ARGV[0]
qual_path = ARGV[1]
name = ARGV[2]


out_fasta = name+'.fasta'
out_qual = name+'.fasta.qual'

puts "Opening #{fasta_path}, #{qual_path}"

fqr=FastaQualFile.new(fasta_path,qual_path,true)

out_f=File.new(out_fasta,'w+')
out_q=File.new(out_qual,'w+')

c=0

fqr.each do |n,f,q|

  out_f.puts ">#{n}"
	out_q.puts ">#{n}"
	
	if n.index('dir=F')
		out_f.puts f.reverse.tr('actgACTG','tgacTGAC')
		out_q.puts q.reverse.join(' ')
	else
		out_f.puts f		 
		out_q.puts q.join(' ')
	end

	c=c+1
end

puts c

fqr.close

out_f.close
out_q.close

