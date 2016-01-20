require "plugin"

########################################################
# Author: Dario Guerrero
# 
# Defines the main methods that are necessary to execute PluginSizeTrim
# Inherit: Plugin
# Trims the output sequences to a fixed size
########################################################

class PluginSizeTrim < Plugin 
   
  def exec_seq(seq,blast_query)
    #$LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking if insert of sequence has enought size" 
    # puts "inserto #{seq.insert_start}, #{seq.insert_end} size #{seq.seq_fasta.size}" 
    

    tr_size = @params.get_param('trim_size_file_'+(seq.order_in_tuple+1).to_s)

    trim_size=-1

    if tr_size
      trim_size=tr_size.to_i
    end 

   # $WORKER_LOG.info "TRIM_SIZE=#{trim_size}, #{seq.order_in_tuple+1}"

    if trim_size>0

      if (seq.seq_fasta.size > trim_size)
      a_beg,a_end = trim_size, seq.seq_fasta.size  # position from an empty insert 
    
        actions=[]  
    
         type = "ActionTrim"
         
         a=seq.new_action(a_beg,a_end,type) 
         actions.push a                     
         add_stats('trim_sizes',a_end-a_beg+1)
         
        seq.add_actions(actions)  
      end  
    end
          
  end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    self.check_param(errors,params,'trim_size_file_1','Integer',-1)
    self.check_param(errors,params,'trim_size_file_2','Integer',-1)
    
    return errors
  end
  
  
end
