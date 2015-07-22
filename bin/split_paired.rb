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

linker = 'TCGTATAACTTCGTATAATGTATGCTATACGAAGTTATTACG'

fqr.each do |n,f,q|
	l_start= 0
	l_end=f.index(linker)

	if l_end
		r_start=l_end+linker.length
		r_end =f.length
		
		forward=f[l_start..l_end-1]
		reverse=f[r_start..r_end]
		
		forward_q = q[l_start..l_end-1]
		reverse_q = q[r_start..r_end]
		
		if (forward.length!=forward_q.length) || (reverse.length!=reverse_q.length)
			puts [forward.length,forward_q.length,reverse.length,reverse_q.length].join(',')
		end
		
		out_f.puts ">#{n}F template=#{n} dir=F library=unadeellas"
		out_f.puts forward 
		out_f.puts ">#{n}R template=#{n} dir=R library=unadeellas"
		out_f.puts reverse
		
		out_q.puts ">#{n}F template=#{n} dir=F library=unadeellas"
		out_q.puts forward_q.join(' ') 
		out_q.puts ">#{n}R template=#{n} dir=R library=unadeellas"
		out_q.puts reverse_q.join(' ')
		
		 
	end

	c=c+1
end

puts c

fqr.close

out_f.close
out_q.close

