require "plugin"

require "make_blast_db"
########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute PluginContaminants
# Inherit: Plugin
########################################################

class PluginContaminants < Plugin


  MAX_TARGETS_SEQS=4 #MAXIMUM NUMBER OF DIFFERENT ALIGNED SEQUENCES TO  KEEP FROM BLAST DATABASE


  def near_to_extrem(c,seq,min_cont_size)
    max_to_extreme=(min_cont_size/2).to_i
    return ((c.q_beg-max_to_extreme<0) || (( c.q_end+max_to_extreme)>=seq.seq_fasta.size-1) ) #return if vector is very near to the extremes of insert)
  end

  def do_blasts(seqs)
    # find MIDS  with less results than max_target_seqs value
    # blast = BatchBlast.new("-db #{@params.get_param('contaminants_db')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_contaminants')} -perc_identity #{@params.get_param('blast_percent_contaminants')} -culling_limit 1")  #get contaminants -max_target_seqs #{MAX_TARGETS_SEQS}

    # TODO - Culling limit = 2 porque el blast falla con este comando cuando se le pasa cl=1 y dust=no
    # y una secuencia de baja complejidad como entrada

    blast = BatchBlast.new("-db #{@params.get_param('contaminants_db')}",'blastn'," -task blastn -evalue #{@params.get_param('blast_evalue_contaminants')} -perc_identity #{@params.get_param('blast_percent_contaminants')} -culling_limit 1")  #get contaminants -max_target_seqs #{MAX_TARGETS_SEQS}

    $LOG.debug('BLAST:'+blast.get_blast_cmd(:xml))

    fastas=[]

    seqs.each do |seq|
      fastas.push ">"+seq.seq_name
      fastas.push seq.seq_fasta
    end

    # fastas=fastas.join("\n")
    # $LOG.info('doing blast to:')
    # $LOG.info('-'*20)
    # $LOG.info(fastas)
    # $LOG.info('-'*20)

    #blast_table_results = blast.do_blast(fastas,:xml)
    t1=Time.now
    blast_table_results = blast.do_blast(fastas,:xml,false)
    add_plugin_stats('execution_time','blast',Time.now-t1)

    t1=Time.now
    blast_table_results = BlastStreamxmlResult.new(blast_table_results)
    add_plugin_stats('execution_time','parse',Time.now-t1)

    # $LOG.info(blast_table_results.inspect)

    return blast_table_results
  end

  # TODO - Contaminants databases grouped by folders
  # TODO - User can select a set of contaminants folders


  def exec_seq(seq,blast_query)
    
    user_conts=seq.get_actions(ActionUserContaminant)
    
    if (!user_conts.nil?) && (!user_conts.empty?)
      return
    end
    
    if blast_query.query_def != seq.seq_name
      raise "Blast and seq names does not match, blast:#{blast_query.query_def} sn:#{seq.seq_name}"
    end

    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for contaminants into the sequence"


    #blast = BatchBlast.new('-db DB/formatted/contaminants.fasta','blastn',' -task blastn -evalue 1e-10 -perc_identity 95')  #get contaminants
    # blast = BatchBlast.new("-db #{@params.get_param('contaminants_db')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_contaminants')} -perc_identity #{@params.get_param('blast_percent_contaminants')} -culling_limit 1")  #get contaminants -max_target_seqs #{MAX_TARGETS_SEQS}


    # blast_table_results = blast.do_blast(seq.seq_fasta,:xml)             #rise seq to contaminants  executing over blast


    #blast_table_results = BlastTableResult.new(res)

    type = "ActionIsContaminated"

    contaminants=[]

    contaminants_ids=[]

    # blast_table_results.querys.each do |query|     #first round to save contaminants without overlap
    # contaminants_ids.push query.hits.definition if (not contaminants_ids.include?(query.hits.definition))
    merge_hits(blast_query.hits,contaminants,contaminants_ids)
    # end




    begin
      contaminants2=contaminants
      contaminants = []                            #second round to save contaminants without overlap
      merge_hits(contaminants2,contaminants)
      #  DONE describir cada ID contaminante encontradomerge_hits(contaminants2,contaminants,ids_contaminants)
    end until (contaminants2.count == contaminants.count)


    actions=[]
    contaminants_size=0

    # @stats[:contaminants_size]={}
    # @stats['contaminants_size']={}
    # @stats['rejected_seqs']={}

    min_cont_size=@params.get_param('min_contam_seq_presence').to_i

    contaminants.each do |c|
      contaminants_size=c.q_end - c.q_beg + 1
      #if ( (@params.get_param('genus')!=c.subject_id.split('_')[1]) &&
      valid_genus=@params.get_param('genus').empty? || !c.definition.upcase.index(@params.get_param('genus').upcase)

      if (valid_genus) &&
          (contaminants_size>=min_cont_size)

        #( (min_cont_size<=contaminants_size) || (near_to_extrem(c,seq,min_cont_size)) ) )

        if !seq.range_inside_action_type?(c.q_beg,c.q_end,ActionVectors)

          # puts "DIFFERENT SPECIE #{specie} ,#{hit.subject_id.split('_')[1].to_s}"
          a = seq.new_action(c.q_beg,c.q_end,type) # adds the correspondent action to the sequence
          a.message = c.definition

          a.found_definition = contaminants_ids    # save the contaminants definitions, each separately
          actions.push a

          contaminants_size=c.q_end-c.q_beg+1

          # if @stats[:contaminants_size][contaminants_size].nil?
          #           @stats[:contaminants_size][contaminants_size] = 0
          #        end
          #
          #        @stats[:contaminants_size][contaminants_size] += 1
          add_stats('contaminants_size',contaminants_size)
          contaminants_ids.each do |c|
            add_stats('contaminants_ids',c)
          end

        end
      else
        $LOG.debug('Contaminant ignored due to genus match: '+c.definition)
      end
    end

    reject=@params.get_param('contaminants_reject')
    # cond_if=false
    #   cond_if=true if (not actions.empty? ) && (reject=='true')
    #
    #   puts "Before check SEQ_REJECTED= TRUE  (reject= .#{reject}. #{reject.class}&& not actions empty= #{not actions.empty?} ) == #{cond_if} >>> "



    if ((not actions.empty? ) && (reject.to_s=='true'))
      #reject sequence
      # puts "SEQ_REJECTED= TRUE >>> "
      seq.seq_rejected=true
      seq.seq_rejected_by_message='contaminated'

      # @stats[:rejected_seqs]={'rejected_seqs_by_contaminants' => 1}
      add_stats('rejected','contaminated')

    end

    seq.add_actions(actions)


  end

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]


    comment='Blast E-value used as cut-off when searching for contaminations'
    default_value = 1e-10
    params.check_param(errors,'blast_evalue_contaminants','Float',default_value,comment)

    comment='Minimum required identity (%) for a reliable contamination'
    default_value = 85
    params.check_param(errors,'blast_percent_contaminants','Integer',default_value,comment)

    comment='Minimum hit size (nt) for considering a true contamination'
    default_value = 40
    params.check_param(errors,'min_contam_seq_presence','Integer',default_value,comment)

    comment='Genus of input data: contaminations belonging to this genus will be ignored'
    default_value = ''
    params.check_param(errors,'genus','String',default_value,comment)

    comment='Is a contamination considered a source of sequence rejection? (setting to false will only trim contaminated sequences instead of rejecting the complete read)'
    default_value = 'true'
    params.check_param(errors,'contaminants_reject','String',default_value,comment)


    comment='Path for contaminants database'
    default_value = File.join($FORMATTED_DB_PATH,'contaminants.fasta')
    params.check_param(errors,'contaminants_db','DB',default_value,comment)


    return errors
  end


end
