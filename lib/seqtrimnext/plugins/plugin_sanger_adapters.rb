require "plugin"

########################################################
# Author: DGF y ABR                      
# 
# Defines the main methods that are necessary to execute PluginAdapters                                                     
# Inherit: Plugin
########################################################

class PluginSangerAdapters < Plugin
  
  # adapters found at end of sequence are even 2 nt wide, cut in 5 because of statistics
  MIN_ADAPTER_SIZE = 5
  MIN_FAR_ADAPTER_SIZE = 13
  MIN_LEFT_ADAPTER_SIZE = 9
 
 def do_blasts(seqs)
    
    # find MIDS  with less results than max_target_seqs value 
    blast=BatchBlast.new("-db #{@params.get_param('adapters_sanger_db')}",'blastn'," -task blastn-short -perc_identity #{@params.get_param('blast_percent_sanger')} -word_size #{MIN_ADAPTER_SIZE}")  
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
   # hits.reverse_each do |hit|
   #  # if (hit.q_end < (end_pos-40)) && ((hit.q_end-hit.q_beg+1)<(@params.get_sanger_adapter(hit.subject_id).length*0.80).to_i)
   #  if ((hit.q_end-hit.q_beg+1)<(@params.get_sanger_adapter(hit.subject_id).length*0.80).to_i)
   #    hits.delete(hit)
   #  end
   # end
   
 end

 def filter_adapters(adapters)

  min_size=@params.get_param('min_sanger_adapter_size').to_i
  adapters.reverse_each do |c|
    adapter_size=c.q_end-c.q_beg+1

    if adapter_size < min_size
      adapters.delete(c)
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
     
     # filter_hits(blast_query.hits, seq.seq_fasta.length)
    
    adapters=[]
    # blast_table_results.querys.each do |query|     # first round to save adapters without overlap
      merge_hits(blast_query.hits,adapters)
    # end

    begin 
      adapters2=adapters                            # second round to save adapters without overlap
      adapters = []
      merge_hits(adapters2,adapters)
    end until (adapters2.count == adapters.count)

    # type = 'ActionAbAdapter'
    actions=[]   
    adapter_size=0 

    filter_adapters(adapters)

    if adapters.count==1 # only one adapter
      c=adapters.first
      adapter_size=c.q_end-c.q_beg+1
      message = c.subject_id 
      type = 'ActionSangerLeftAdapter'
      stat_type='left'
      add_stats('adapter_type',stat_type)

      a = seq.new_action(c.q_beg,c.q_end,type)
      a.message = message 
      a.reversed = c.reversed 
      a.left_action = true
      actions.push a
             
      add_stats('adapter_size',adapter_size) 
      add_stats('adapter_id',message)

    elsif adapters.count >=2
      type = 'ActionSangerLeftAdapter'
      stat_type='left'
      left_action=true
      right_action=false

      adapters.sort!{|a1,a2| a1.q_beg <=> a2.q_beg}
      old_qend=adapters.first.q_end
      
      max_slice_size=[]

      # left_qend=adapters.first.q_end
      adapters.each do |c|                           # adds the correspondent action to the sequence 


        # check if it is a right adapter
        if c.q_beg > (old_qend+50)
          type=type = 'ActionSangerRightAdapter'
          stat_type='right'
          left_action=false
          right_action=true
        end

        adapter_size=c.q_end-c.q_beg+1
        message = c.subject_id 
        add_stats('adapter_type',stat_type)

        a = seq.new_action(c.q_beg,c.q_end,type)
        a.message = message 
        a.reversed = c.reversed 
        a.left_action = left_action
        a.right_action = right_action

        # if action.last.q_end - a.start_pos > max_slice_size.last[:size]
        
        # end

        actions.push a
      
        add_stats('adapter_size',adapter_size)
        add_stats('adapter_id',message)

        old_qend=adapters.first.q_end

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
    
    comment='Blast E-value used as cut-off when searching for Sanger adapters'
    # default_value = 1e-6
    default_value = 1
    params.check_param(errors,'blast_evalue_sanger','Float',default_value,comment)
    
    comment='Minimum required identity (%) for a reliable Sanger adapter'
    default_value = 95
    params.check_param(errors,'blast_percent_sanger','Integer',default_value,comment)

    comment='Minimum required adapter size for a valid Sanger adapter'
    default_value = 10
    params.check_param(errors,'min_sanger_adapter_size','Integer',default_value,comment)
    
    comment='Path for Sanger adapters database'
    default_value = File.join($FORMATTED_DB_PATH,'adapters_sanger.fasta')
    params.check_param(errors,'adapters_sanger_db','DB',default_value,comment)
    
    return errors
  end
  
  def self.get_graph_title(plugin_name,stats_name)
    case stats_name
    when 'adapter_type'
      'Sanger adapters by type'
    when 'adapter_size'
      'Sanger adapters by size'
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
