require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginPairedReads                                                     
# Inherit: Plugin
########################################################
class ActionPairedReads < SeqtrimAction    
  def initialize(start_pos,end_pos)
     super(start_pos,end_pos)    
     @cut =true

   end
 
  
   def apply_to(seq)
     $LOG.debug "Applying #{self.class}"
     
     #Storage the first and second subsequences
     subseq1 = seq.seq_fasta[0,@start_pos-1]        
     subseq2 = seq.seq_fasta[@end_pos+1,seq.seq_fasta.length-1]
     #$LOG.debug "\nSubsequence left: #{subseq1} \n Subsequence right: #{subseq2}}"

   end
  
  
end
