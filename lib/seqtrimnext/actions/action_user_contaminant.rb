require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute Plugin1                                                     
# Inherit: Plugin
########################################################

class ActionUserContaminant < SeqtrimAction
      
   def initialize(start_pos,end_pos)
     super(start_pos,end_pos)
     @cut =false
   end

   def apply_decoration(char)
     return char.yellow
  
   end       


end
