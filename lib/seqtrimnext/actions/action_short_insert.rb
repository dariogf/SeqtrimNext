require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute ActionShortInserted                                                     
# Inherit: Plugin
########################################################

class ActionShortInsert < SeqtrimAction

  def initialize(start_pos,end_pos)
    super(start_pos,end_pos)    
    # @cut =true  
    @cut = false
    @informative = true
  end
     
# def apply_to(seq)
#   
#    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
#    $LOG.debug " Applying #{self.class}. ------ Error.Sequence is not good ------ . BEGIN: #{@start_pos}   END: #{@end_pos}  " 
#  
#   
# end 

def apply_decoration(char)
  return char.on_red
end             


end
