require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute Plugin1                                                     
# Inherit: Plugin
########################################################

class ActionUnexpectedPolyT < SeqtrimAction
  def initialize(start_pos,end_pos)
    super(start_pos,end_pos)    
    @cut =true
  end

# def apply_to(seq)
#   
#    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
#    $LOG.debug " Applying #{self.class} " 
#   
# end  


def apply_decoration(char)
  return char.bold
end  


end
