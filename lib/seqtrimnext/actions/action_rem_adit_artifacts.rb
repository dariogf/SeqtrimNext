require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginActionLowHighSize                                                     
# Inherit: Plugin
########################################################

class ActionRemAditArtifacts < SeqtrimAction      
  
  def initialize(start_pos,end_pos)
     super(start_pos,end_pos)    
     @cut =true

   end
   
# def apply_to(seq)
#   
#    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
#    $LOG.debug " Applying #{self.class}  to #{seq.seq_name}  " 
#    #delete sequence if it was created
#    
#   
# end 

def apply_decoration(char)
  return char.yellow.negative
end    


end
