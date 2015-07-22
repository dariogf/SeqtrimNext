# require '../utils/fasta_qual_reader' #descomentar en test_extracts
require 'fasta_qual_reader'   #descomentar en seqtrimii



require 'make_blast_db'
require 'scbi_blast'




######################################
# Author:: Almudena Bocinos Rioboo
# Extract stats like mean of sequence's length 
# Inherit:: FastaReader
######################################

class Piro < FastaQualReader
  #attr_accessor :na
  def initialize(path_fasta,path_qual)
    @path_fasta=path_fasta
    super(path_fasta,path_qual)
    MakeBlastDb.execute('../sequences/gemini.fasta')
    
    
  end
  
  def on_process_sequence(name_seq,fasta_seq,qual_seq)
    puts "in piro, in on process sequence, #{name_seq}"
    
   
    blast = BatchBlast.new('-db '+ @path_fasta ,'blastn',' -task blastn -evalue 1e-10 -perc_identity 95')  #get contaminants
    #blast = BatchBlast.new('DB/vectors.fasta','blastn',' -task blastn ')  #get vectors

     $LOG.debug "-------OK----"

    # puts seq.seq_fasta
     res = blast.do_blast(fasta_seq)             #rise seq to contaminants  executing over blast
    # 
    #     blast_table_results = BlastTableResult.new(res,nil)
    
    # vectors=[]
    #     blast_table_results.querys.each do |query|     # first round to save contaminants without overlap
    #       merge_hits(query.hits,vectors)
    #     end
    # 
    #     begin 
    #       vectors2=vectors                            # second round to save contaminants without overlap
    #       vectors = []
    #       merge_hits(vectors2,vectors)
    #     end until (vectors2.count == vectors.count) 
    # 
    # 
    #     vectors.each do |c|                           # adds the correspondent action to the sequence
    #       #if @seq_specie!=seq_specie-contaminant
    # 
    #       if (@params.get_param('genus')!=c.subject_id.split('_')[1])
    #          # puts "DIFFERENT SPECIE #{specie} ,#{hit.subject_id.split('_')[1].to_s}"
    #          a = seq.add_action(c.q_beg,c.q_end,type)
    #          a.message = c.subject_id
    #       end
    #     end
    
    
  end
  
  def on_end_process()
    


    
 
 
  end
  

  
end
