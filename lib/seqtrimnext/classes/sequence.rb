########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the class Sequence's attribute                                                     
# 
########################################################

class Sequence
  #storages the name and the contains from fasta sequence
  def initialize(seq_name,seq_fasta,seq_qual, seq_comment = '')     
      
      @seq_fasta=seq_fasta
      @seq_name=seq_name
      @seq_qual=seq_qual           
      @seq_comment = seq_comment
      
      @seq_rejected=false   
      @seq_repeated=false
      @seq_reversed=false 
      
      @seq_rejected_by_message=''
      
      @ns_present = ns_present?
      @xs_present = xs_present?
      
      
      
      # puts "INIT SEQ >>>> #{seq_name} #{seq_specie}"
      
  end
  
  attr_accessor :seq_name, :seq_fasta, :seq_qual, :seq_comment , :seq_rejected, :seq_repeated , :seq_reversed 
  attr_accessor :seq_rejected_by_message
  
  def ns_present?
    return (@seq_fasta.index('N')  != nil)
  end
  
  def xs_present?
    return (@seq_fasta.index('X') != nil)
  end
  
  def seq_is_long_enough(seq_min_length)
    return (@seq_fasta.length>=seq_min_length)
  end
  
  def to_fasta
  		return ">"+@seq_name.to_s+"\n"+@seq_fasta  
  end
  
  def to_qual
  		return ">"+@seq_name.to_s+"\n"+"#{@seq_qual}"  
  end
  
end
