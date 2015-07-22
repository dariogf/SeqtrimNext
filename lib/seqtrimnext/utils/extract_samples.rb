require "fasta_reader.rb"


######################################
# Author:: Almudena Bocinos Rioboo
# Extract ramdom sequences until "num_seqs" 
# Inherit:: FastaReader
######################################

class ExtractSamples < FastaReader
  attr_accessor :num_seqs
  def initialize(file_name)
    @num_seqs = 0
    super(file_name)
  end

       # override begin processing
 def on_begin_process()
    $LOG.info " Begin Extract Samples"
    @fich = File.open("results/Sample.txt",'w') 
    @max = 1000
    
 end
 
    # override processing sequence
  def on_process_sequence(seq_name,seq_fasta)
      ra_seq = Kernel.rand
     
      if ((@num_seqs < @max) and (ra_seq>0.5)) #if cond is successful then, choose a part from this sequence
        #calculate the part from the sequence
        width = (Kernel.rand * 50 ) + 300
        ra_part1 = Kernel.rand * (seq_fasta.length-width)
        ra_part2 = ra_part1 + width
        sub_seq_fasta = seq_fasta.slice(ra_part1,ra_part2)
        
        @fich.puts "#{seq_name} "
        @fich.puts "#{sub_seq_fasta} "
        @num_seqs += 1
        
      end
      
  end
    
    

       #override end processing
 def on_end_process()
    $LOG.info "All Samples have been extracted"
    @fich.close
 end

end