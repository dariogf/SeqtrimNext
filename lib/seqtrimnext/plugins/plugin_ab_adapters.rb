require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginAdapters                                                     
# Inherit: Plugin
########################################################

class PluginAbAdapters < Plugin
  
  # adapters found at end of sequence are even 2 nt wide, cut in 5 because of statistics
  MIN_ADAPTER_SIZE = 5
  MIN_FAR_ADAPTER_SIZE = 13
  MIN_LEFT_ADAPTER_SIZE = 9
 
 def do_blasts(seqs)
    
    # find MIDS  with less results than max_target_seqs value 
    blast=BatchBlast.new("-db #{@params.get_param('adapters_ab_db')}",'blastn'," -task blastn-short -perc_identity #{@params.get_param('blast_percent_ab')} -word_size #{MIN_ADAPTER_SIZE}")  
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
 
 # filter hits that are far the extreme and do not have a valid length
 def filter_hits(hits,end_pos)
   hits.reverse_each do |hit|
    if (hit.q_end < (end_pos-40)) && ((hit.q_end-hit.q_beg+1)<(@params.get_ab_adapter(hit.subject_id).length*0.80).to_i)
      hits.delete(hit)
    #   puts "DELETE #{hit.inspect}"
    # else
    #   puts "ACCEPTED #{hit.inspect}, >= #{(@params.get_ab_adapter(hit.subject_id).length*0.2).to_i}"
    end
   end
   
 end
 
 def exec_seq(seq,blast_query)
   if blast_query.query_id != seq.seq_name
     raise "Blast and seq names does not match, blast:#{blast_query.query_id} sn:#{seq.seq_name}"
   end
   
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for adapters into the sequence" 
  
        
    # blast=BatchBlast.new("-db #{File.join($FORMATTED_DB_PATH,'adapters_ab.fasta')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_ab')} -perc_identity #{@params.get_param('blast_percent_ab')} -word_size #{MIN_ADAPTER_SIZE}")  
    
    
    
    # blast with only one sequence, no with many sequences from a database
    #---------------------------------------------------------------------
    
    # blast_table_results = blast.do_blast(seq.seq_fasta)             #rise seq to adapterss  executing over blast
    
     #BlastTableResult.new(res)
     # puts blast_query.inspect
     # puts blast_table_results.inspect
     
     filter_hits(blast_query.hits, seq.seq_fasta.length)
    
    adapters=[]
    # blast_table_results.querys.each do |query|     # first round to save adapters without overlap
      merge_hits(blast_query.hits,adapters)
    # end

    begin 
      adapters2=adapters                            # second round to save adapters without overlap
      adapters = []
      merge_hits(adapters2,adapters)
    end until (adapters2.count == adapters.count)

    # puts "MERGED"
    # puts "="*50
    # adapters.each {|a| puts a.inspect}
    
    max_to_end=@params.get_param('max_ab_to_end').to_i
    # type = 'ActionAbAdapter'
    actions=[]   
    adapter_size=0 
    
    #@stats['adapter_size']={}
    adapters.each do |c|                           # adds the correspondent action to the sequence 
      # puts "is the adapter near to the end of sequence ? #{c.q_end+seq.insert_start+max_to_end} >= ? #{seq.seq_fasta_orig.size-1}"   
        adapter_size=c.q_end-c.q_beg+1
        #if ((c.q_end+seq.insert_start+max_to_end)>=seq.seq_fasta_orig.size-1)  
        right_action = true
        #if ab adapter is very near to the end of original sequence
	      if c.q_end>=seq.seq_fasta.length-max_to_end
          message = c.subject_id 
          type = 'ActionAbAdapter'
          ignore=false 
          add_stats('adapter_type','normal') 
        
        elsif (c.q_beg <= 4) && (adapter_size>=MIN_LEFT_ADAPTER_SIZE) #left adapter
          message = c.subject_id    
          type = 'ActionAbLeftAdapter'
          ignore = false
          right_action = false
          add_stats('adapter_type','left') 
        elsif (adapter_size>=MIN_FAR_ADAPTER_SIZE)
          message = c.subject_id    
          type = 'ActionAbFarAdapter'
          ignore = false
          add_stats('adapter_type','far') 
        else
          ignore=true 
        end 
        
        if !ignore
          a = seq.new_action(c.q_beg,c.q_end,type) 
          a.message = message 
          a.reversed = c.reversed 
          if right_action
            a.right_action = true    #mark as rigth action to get the left insert
          else
            a.left_action = true
          end
          actions.push a  
        
          # puts "adapter_size #{adapter_size}"

          #@stats[:adapter_size]={adapter_size => 1} 
          add_stats('adapter_size',adapter_size) 
          add_stats('adapter_id',message)
        end 
    end 
    
    if !actions.empty?
      seq.add_actions(actions)   
      add_stats('sequences_with_adapter','count')
    end
    
    
    #    
  end

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Blast E-value used as cut-off when searching for 454 AB adapters'
    # default_value = 1e-6
		default_value = 1
		params.check_param(errors,'blast_evalue_ab','Float',default_value,comment)
		
		comment='Minimum required identity (%) for a reliable 454 AB adapter'
		default_value = 95
		params.check_param(errors,'blast_percent_ab','Integer',default_value,comment)
		
    comment='454 AB adapters can be found only at the read end (not within it). The following variable indicates the number of nucleotides that are allowed for considering the AB adapters to be located at the end'
		default_value = 9
		params.check_param(errors,'max_ab_to_end','Integer',default_value,comment)
    
    comment='Path for 454 AB adapters database'
		default_value = File.join($FORMATTED_DB_PATH,'adapters_ab.fasta')
		params.check_param(errors,'adapters_ab_db','DB',default_value,comment)
    
    return errors
  end
  
  def self.get_graph_title(plugin_name,stats_name)
    case stats_name
    when 'adapter_type'
      'AB adapters by type'
    when 'adapter_size'
      'AB adapters by size'
    end
  end

  def self.get_graph_filename(plugin_name,stats_name)
    return stats_name
    
    # case stats_name
    # when 'adapter_type'
    #   'AB adapters by type'
    # when 'adapter_size'
    #   'AB adapters by size'
    # end
  end
  
  def self.valid_graphs
    return ['adapter_type']
  end

  
end
