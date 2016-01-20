require "seqtrim_action"

########################################################
# Author: Dario Guerrero                      
# 
# Defines the main methods that are necessary to execute Plugin1                                                     
# Inherit: Plugin
########################################################

class ActionTrim < SeqtrimAction
  def initialize(start_pos,end_pos)
    
    super(start_pos,end_pos)
    @cut =true 
  end

  def apply_decoration(char)
  	return char.red.italic
  end  

end
