########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute PluginLowComplexity

#
# Inherit: Plugin
########################################################

require "plugin"

MIN_DUST_SIZE = 30

class PluginLowComplexity < Plugin
  
  # do the dust masker instead of blast
  def do_blasts(seqs)

     dust_masker=DustMasker.new()

     fastas=[]
     
     seqs.each do |seq|
      fastas.push ">"+seq.seq_name
      fastas.push seq.seq_fasta
     end
     
     # fastas=fastas.join("\n")
     
     found_dust = dust_masker.do_dust(fastas)
     # puts found_dust
     # puts blast_table_results.inspect
    
     return found_dust
  end
  
  
  def exec_seq(seq,blast_query)
    dust_query=blast_query
    
    if dust_query.query_id != seq.seq_name
      raise "Blast and seq names does not match, blast:#{blast_query.query_id} sn:#{seq.seq_name}"
    end
    actions=[]

      # puts "Checking for dust: #{seq.seq_fasta}"
      # puts found_dust.to_json
      total_dust=0
      if !dust_query.nil?
        # low_quals=seq.get_actions(ActionLowQuality)
        
        dust_query.dust.each do |dust|
          start=dust[0]
          stop=dust[1]
          dust_size=dust[1]-dust[0]+1
          

          if (dust_size)>=MIN_DUST_SIZE
          
            # check if low complexity is inside a lowqual region
            if !seq.range_inside_action_type?(start,stop,ActionLowQuality)
              
              total_dust+=dust_size    
              a = seq.new_action(start,stop,'ActionLowComplexity')
              # a.left_action=true
              actions.push a
              
            end
            # break
          end
        end
      end
      
      if !actions.empty?
        add_stats('low_complexity',total_dust)
        seq.add_file_tag(0, 'low_complexity', :both, 100)
        seq.add_actions(actions)
      end

  end



  ######################################################################
  #---------------------------------------------------------------------

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]

    # 
    # comment='Minimum percent of T bases in poly_a to be accepted'
    # default_value = 80
    # params.check_param(errors,'poly_t_percent','Integer',default_value,comment)
    # 

    return errors
  end


end
