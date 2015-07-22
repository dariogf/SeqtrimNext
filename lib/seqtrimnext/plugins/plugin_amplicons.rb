require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute PluginAdapters
# Inherit: Plugin
########################################################

class PluginAmplicons < Plugin


  def do_blasts(seqs)
    # find MIDS  with less results than max_target_seqs value
    blast=BatchBlast.new("-db #{@params.get_param('primers_db')}",'blastn'," -task blastn-short -perc_identity #{@params.get_param('blast_percent_primers')}")
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

    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for primers into the sequence"

    # puts blast_query.inspect
    
    # merge hits
    # primers=blast_query.merged_hits!
    
    # do not merge hits, since id is important
    primers=blast_query.hits
    
    min_primer_size=@params.get_param('min_primer_size').to_i
    # puts "MERGED:"
    # puts primers.inspect

    # type = 'ActionAbAdapter'
    actions=[]
    adapter_size=0

    # filter primers by size
    primers = primers.select{|primer| (primer.size >= min_primer_size)}.sort{|p1,p2| p1.size<=>p2.size}.reverse
    # puts "FILTERED:"
    # puts primers.inspect
    
    # reject sequences with less than two primers
    if primers.count < 2

      seq.seq_rejected=true
      seq.seq_rejected_by_message='Primer pair not found'

      # @stats[:rejected_seqs]={'rejected_seqs_by_contaminants' => 1}
      add_stats('rejected','primers_not_found')

    else # has two primers, or more

      if seq.seq_fasta.index('N')
        seq.seq_rejected=true
        seq.seq_rejected_by_message='At least one N found'

        # @stats[:rejected_seqs]={'rejected_seqs_by_contaminants' => 1}
        add_stats('rejected','one_n_found')

      else
        # puts "EL DE ARRIBA"
        
        # take first two primers and order them by qbeg
        left_primer = primers[0..1].sort{|p1,p2| p1.q_beg<=>p2.q_beg}.first
        right_primer = primers[0..1].sort{|p1,p2| p1.q_beg<=>p2.q_beg}.last
        
        # puts "LEFT_PRIMER:"
        # puts left_primer.inspect
        # puts "RIGHT_PRIMER:"
        # puts right_primer.inspect

        # if (left_primer.size>= min_primer_size) && (right_primer.size>= min_primer_size)

          a = seq.new_action(left_primer.q_beg,left_primer.q_end,'ActionLeftPrimer')
          a.message = left_primer.subject_id
          a.tag_id = left_primer.subject_id
          a.reversed = left_primer.reversed
          a.left_action = true
          actions.push a

          add_stats('primer_size',left_primer.size)
          add_stats('primer_id',left_primer.subject_id)

          a = seq.new_action(right_primer.q_beg,right_primer.q_end,'ActionRightPrimer')
          a.message = right_primer.subject_id
          a.reversed = right_primer.reversed
          a.tag_id = right_primer.subject_id
          a.right_action = true
          actions.push a

          add_stats('primer_size',right_primer.size)
          add_stats('primer_id',right_primer.subject_id)
          
          seq.add_file_tag(2, left_primer.subject_id, :file)
          seq.add_file_tag(2, right_primer.subject_id, :file)
          

        # end


        if !actions.empty?
          seq.add_actions(actions)
          add_stats('sequences_with_primers','count')
          
          # add_stats('sequences',seq.seq_fasta)
        end

      end
      #
    end
  end

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]

    comment='Blast E-value used as cut-off when searching for primers'
    # default_value = 1e-6
    default_value = 1
    params.check_param(errors,'blast_evalue_primers','Float',default_value,comment)

    comment='Minimum required identity (%) for a reliable primer'
    default_value = 95
    params.check_param(errors,'blast_percent_primers','Integer',default_value,comment)

    comment='Minimun primer size'
    default_value = 15
    params.check_param(errors,'min_primer_size','Integer',default_value,comment)

    comment='Path for primers database'
    # default_value = File.join($FORMATTED_DB_PATH,'adapters_ab.fasta')
    default_value=nil
    params.check_param(errors,'primers_db','DB',default_value,comment)

    return errors
  end

  # def self.get_graph_title(plugin_name,stats_name)
  #   case stats_name
  #   when 'adapter_type'
  #     'AB adapters by type'
  #   when 'adapter_size'
  #     'AB adapters by size'
  #   end
  # end
  #
  # def self.get_graph_filename(plugin_name,stats_name)
  #   return stats_name
  #
  #   # case stats_name
  #   # when 'adapter_type'
  #   #   'AB adapters by type'
  #   # when 'adapter_size'
  #   #   'AB adapters by size'
  #   # end
  # end
  #
  # def self.valid_graphs
  #   return ['adapter_type']
  # end
  
  # def self.plot_setup(stats_value,stats_name,x,y,init_stats,plot)
  # 
  #   # puts "============== #{stats_name}"
  #   
  #   # puts stats_name
  #   case stats_name
  #     
  #   when 'primer_size'
  #     plot.x_label= "Length"
  #     plot.y_label= "Count"
  #     # plot.x_range="[0:#{init_stats['biggest_sequence_size'].to_i}]"
  #     plot.x_range="[0:200]"
  #     puts x.class
  #     plot.add_x(x)
  #     plot.add_y(y)
  #     
  #     plot.do_graph
  #     
  #     return true
  #   else
  #     return false
  #   end
  #   
  # end


end
