require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginActionLowHighSize                                                     
# Inherit: Plugin
########################################################

class ActionLowQuality < SeqtrimAction    
  
  def initialize(start_pos,end_pos)
     super(start_pos,end_pos)    
     # esto es cut=false porque al principio el plugin lowqual estaba al inicio del pipeline y habia que dejar 
     # la secuencia larga para que se encontrasen los contaminantes y vectores
     # Tambien esta por si un linker tiene baja calidad que pueda encontrarlo
     @cut =false
   end
   
# def apply_to(seq)
#   
#    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
#    $LOG.debug " Applying #{self.class}  to #{seq.seq_name} . This sequence will be ignored due to low quality " 
#    #delete sequence if it was created
#    
#   
# end   


  def apply_decoration(char)
    return char.downcase.on_white
  end 


end
