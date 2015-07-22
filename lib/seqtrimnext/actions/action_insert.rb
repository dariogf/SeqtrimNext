require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute ActionInserted                                                     
# Inherit: Plugin
########################################################

class ActionInsert < SeqtrimAction
       
  def initialize(start_pos,end_pos)
     super(start_pos,end_pos)    
     @cut =false
     @informative = true
  end

# #this method is launched when the size of inserted is enough   
# def apply_to(seq)
#    
#    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
#    $LOG.debug " Applying #{self.class}. ------Inserted has enough size ------ . BEGIN: #{@start_pos}   END: #{@end_pos}  " 
#  
#   
# end 

def apply_decoration(char)
  return char
end      
   

end
