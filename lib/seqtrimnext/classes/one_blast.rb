#!/usr/bin/env ruby

class OneBlast

def initialize(database, blast_type = 'blastp')

		@blast_type = blast_type
    @database = database
    @c=0 
end


def do_blast(seq_fasta)

	@f = File.new('one_blast_aux.fasta','w+')
	@f.puts ">SEQNAME_"+@c.to_s
	@f.puts seq_fasta
	@c = @c+1			
	@f.close

    cmd = '~blast/programs/x86_64/bin/blastall -p '+@blast_type+' -d '+@database + ' -i one_blast_aux.fasta -o one_blast_aux.out'
        #puts cmd
        system(cmd)

    res =''
    File.open('one_blast_aux.out').each_line { |line|

        res = line
	

    }

end

def close

end

end


