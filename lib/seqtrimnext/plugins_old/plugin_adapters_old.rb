require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginAdapters                                                     
# Inherit: Plugin
########################################################

class PluginAdaptersOld < Plugin
  
  def get_type_adapter(p_start,p_end,seq)
       #if q_beg is nearer the left, add adapter action by the left,
       #if q_end esta is nearer the right , add adapter action by  the right
       #NOTE: If the adapter is very near from left and rigth,
       #then the sequence isn't valid, because almost sequence is adapter.
       
       
       v1= p_end.to_i
       v2= p_start.to_i   
       
        # puts " startadapter #{v2} endadapter #{v1} insert_start #{seq.insert_start}  insert_end #{seq.insert_end}"
       
        # puts " #{v2+seq.insert_start} <? #{seq.seq_fasta.length - v1 - 1 + seq.seq_fasta_orig.length - seq.insert_end-1}"
       if (v2+seq.insert_start  < (seq.seq_fasta.length - v1 - 1+ seq.seq_fasta_orig.length - seq.insert_end-1)) #IF THE NEAREST ONE IS THE LEFT
         type = "ActionLeftAdapter"          
         
       else
          type = "ActionRightAdapter"
         
       end
       return type
  end 
  
  
  def cut_by_right(adapter,seq)
    
    left_size = adapter.q_beg-seq.insert_start+1
    right_size = seq.insert_end-adapter.q_end+1
    left_size=0 if (left_size<0)
    right_size=0 if (right_size<0) 
    
    return (left_size>(right_size/2).to_i)
    
  end
 
 def do_blasts(seqs)
    # find MIDS  with less results than max_target_seqs value 
    blast=BatchBlast.new("-db #{@params.get_param('adapters_db')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_adapters')} -perc_identity #{@params.get_param('blast_percent_adapters')}")  
    $LOG.debug('BLAST:'+blast.get_blast_cmd)

    fastas=[]
    
    seqs.each do |seq|
     fastas.push ">"+seq.seq_name
     fastas.push seq.seq_fasta
    end
    
    # fastas=fastas.join("\n")
    
    blast_table_results = blast.do_blast(fastas)
    
    # puts blast_table_results.inspect
   
    return blast_table_results
 end
 
 
 def exec_seq(seq,blast_query)
   if blast_query.query_id != seq.seq_name
     raise "Blast and seq names does not match, blast:#{blast_query.query_id} sn:#{seq.seq_name}"
   end
   
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for adapters into the sequence" 
  
        
    # blast=BatchBlast.new("-db #{File.join($FORMATTED_DB_PATH,'adapters.fasta')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_adapters')} -perc_identity #{@params.get_param('blast_percent_adapters')}")  
    
    # blast with only one sequence, no with many sequences from a database
    #---------------------------------------------------------------------
    
    # blast_table_results = blast.do_blast(seq.seq_fasta)             #rise seq to adapterss  executing over blast
    
    #blast_table_results = BlastTableResult.new(res) 
    
    # blast_table_results.inspect         
    
    adapters=[]
    # blast_table_results.querys.each do |query|     # first round to save adapters without overlap
      merge_hits(blast_query,adapters)
    # end

    begin 
      adapters2=adapters                            # second round to save adapters without overlap
      adapters = []
      merge_hits(adapters2,adapters)
    end until (adapters2.count == adapters.count) 

    actions=[] 
    adapter_size=0
    # @stats['adapter_size']={}
    adapters.each do |ad|                           # adds the correspondent action to the sequence  
       
       type = get_type_adapter(ad.q_beg,ad.q_end,seq)
       a = seq.new_action(ad.q_beg,ad.q_end,type) 
       # puts " state left_action #{a.left_action} right_action #{a.right_action}"
         

       adapter_size=ad.q_end-ad.q_beg+1 
       
       if cut_by_right(ad,seq)
        
        # puts "action right end1 #{seq.insert_end}"
        
        a.right_action=true    #mark rigth action to get the left insert
      else 
          
        # puts " cut1 by left #{seq.insert_start} ad #{ad.q_beg+seq.insert_start} #{ad.q_end+seq.insert_start}"
                 
        a.left_action = true   #mark left action to get the right insert        
        
      end 
      
      a.message = ad.subject_id 
      a.reversed = ad.reversed 
      actions.push a 
      
      # @stats[:adapter_size]={adapter_size => 1} 
      add_stats('adapter_size',adapter_size)  
        
    end 
    seq.add_actions(actions)
    #    
  end

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
    comment='Blast E-value used as cut-off when searching for adapters or primers'
    default_value = 1e-6
		params.check_param(errors,'blast_evalue_adapters','Float',default_value,comment)
		
		comment='Minimum required identity (%) for a reliable adapter'
		default_value = 95
		params.check_param(errors,'blast_percent_adapters','Integer',default_value,comment)
    
    comment='Path for adapter database'
		default_value = File.join($FORMATTED_DB_PATH,'adapters.fasta')
		params.check_param(errors,'adapters_db','DB',default_value,comment)		
    
    return errors
  end
  
  
end
