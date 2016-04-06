require "plugin"

require "make_blast_db"
########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute Pluginclassify
# Inherit: Plugin
########################################################

class PluginUserContaminants < Plugin


  MAX_TARGETS_SEQS=4 #MAXIMUM NUMBER OF DIFFERENT ALIGNED SEQUENCES TO  KEEP FROM BLAST DATABASE


  def near_to_extrem(c,seq,min_cont_size)
    max_to_extreme=(min_cont_size/2).to_i
    return ((c.q_beg-max_to_extreme<0) || (( c.q_end+max_to_extreme)>=seq.seq_fasta.size-1) ) #return if vector is very near to the extremes of insert)
  end
  
  def sum_hits_by_id(hits)
    res={}
    
    hits.each do |c|
      hit_size=c.q_end - c.q_beg + 1
      
      res[c.definition] = (res[c.definition]||0)+hit_size
      
    end
    
    puts res.to_json
    return res
  end

  def can_execute?
    return !@params.get_param('user_contaminant_db').empty?
  end


  def do_blasts(seqs)

    # TODO - Culling limit = 2 porque el blast falla con este comando cuando se le pasa cl=1 y dust=no
    # y una secuencia de baja complejidad como entrada

    task_template=@params.get_param('blast_task_template_user_contaminants')
    extra_params=@params.get_param('blast_extra_params_user_contaminants')

    extra_params=extra_params.gsub(/^\"|\"?$/, '')

    blast = BatchBlast.new("-db #{@params.get_param('user_contaminant_db')}",'blastn'," -task #{task_template} #{extra_params} -evalue #{@params.get_param('blast_evalue_user_contaminant')} -perc_identity #{@params.get_param('blast_percent_user_contaminant')} -culling_limit 1")  #get classify -max_target_seqs #{MAX_TARGETS_SEQS}

    $LOG.debug('BLAST:'+blast.get_blast_cmd(:table))

    fastas=[]

    seqs.each do |seq|
      fastas.push ">"+seq.seq_name
      fastas.push seq.seq_fasta
    end


    #blast_table_results = blast.do_blast(fastas,:xml)
    t1=Time.now
    blast_table_results = blast.do_blast(fastas,:table,false)
    add_plugin_stats('execution_time','blast',Time.now-t1)

    t1=Time.now
    #blast_table_results = BlastStreamxmlResult.new(blast_table_results)
    blast_table_results = BlastTableResult.new(blast_table_results)
    add_plugin_stats('execution_time','parse',Time.now-t1)


    return blast_table_results
  end


  def exec_seq(seq,blast_query)
    if blast_query.query_id != seq.seq_name
      raise "Blast and seq names does not match, blast:#{blast_query.query_id} sn:#{seq.seq_name}"
    end

    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for classify into the sequence"

    type = "ActionUserContaminant"

    classify={}
    contaminants=[]

    
    merge_hits(blast_query.hits,contaminants,nil,false)

    begin
      contaminants2=contaminants
      contaminants = []                            #second round to save contaminants without overlap
      merge_hits(contaminants2,contaminants,nil,false)
    end until (contaminants2.count == contaminants.count)
    
    contaminants.sort {|c1,c2| (c1.q_end - c1.q_beg + 1)<=>(c2.q_end - c2.q_beg + 1)}

    # classify=sum_hits_by_id(contaminants.hits)

    actions=[]
    # classify_size=0

    min_cont_size=@params.get_param('min_user_contaminant_size').to_i
    
    # biggest_classify = contaminants.sort {|c1,c2| c1[1]<=>c2[1]}
    
    if !contaminants.empty?

      # definition,classify_size = biggest_classify.last
      
      biggest_contaminant=contaminants.last
      hit_size=(biggest_contaminant.q_end - biggest_contaminant.q_beg + 1)
      
      a = seq.new_action(biggest_contaminant.q_beg,biggest_contaminant.q_end,type) # adds the correspondent action to the sequence

      a.message = biggest_contaminant.definition
      
      seq.add_comment("Contaminated: #{biggest_contaminant.definition}")
      
      a.tag_id = biggest_contaminant.definition.gsub(' ','_')

      # a.found_definition = c.definition    # save the classify definitions, each separately
      
      #save to this file
      seq.add_file_tag(0, 'with_user_contaminant', :both, 10)
      
      actions.push a
      
      add_stats('user_contaminant_size',hit_size)
      add_stats('user_contaminant_ids',biggest_contaminant.definition)
  
      seq.add_actions(actions)
    end

  end

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]


    comment='Blast E-value used as cut-off when searching for contaminations'
    default_value = 1e-10
    params.check_param(errors,'blast_evalue_user_contaminant','Float',default_value,comment)

    comment='Minimum required identity (%) for a reliable user contaminant match'
    default_value = 85
    params.check_param(errors,'blast_percent_user_contaminant','Integer',default_value,comment)

    comment='Minimum hit size (nt) for considering for user contaminant'
    default_value = 30 # era 40
    params.check_param(errors,'min_user_contaminant_size','Integer',default_value,comment)

    comment='Path for user contaminant database'
    default_value = "" #File.join($FORMATTED_DB_PATH,'user_contaminant.fasta')
    params.check_param(errors,'user_contaminant_db','DB',default_value,comment)

    comment='Blast task template for user contaminations'
    default_value = 'blastn'
    params.check_param(errors,'blast_task_template_user_contaminants','String',default_value,comment)

    comment='Blast extra params for user contaminations'
    default_value = ''
    params.check_param(errors,'blast_extra_params_user_contaminants','String',default_value,comment)

    return errors
  end


end
