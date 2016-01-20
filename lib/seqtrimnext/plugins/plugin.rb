########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute a plugin
#
########################################################

require 'string_utils'
# $: << '/Users/dariogf/progs/ruby/gems/scbi_blast/lib'

require 'scbi_blast'

class Plugin

  attr_accessor :stats

  #Loads the plugin's execution whit the sequence "seq"
  def initialize(seq, params)
    @params = params
    @stats ={}
    
    if can_execute?
      t1=Time.now
      execute(seq)
      t2=Time.now
    end
    
    
    @stats['execution_time']={}

    @stats['execution_time']['total_seconds']=t2-t1
  end

  def can_execute?
    return true
  end

  def exec_seq(seq,blast_query)
  end

  #Begins the plugin's execution whit the sequence "seq"
  def execute(seqs)
    blasts=do_blasts(seqs)

    if !blasts.empty?
      
      if blasts.is_a?(Array)
        queries=blasts
      else
        queries = blasts.querys
      end
      
      seqs.each_with_index do |s,i|
        exec_seq(s,queries[i])
      end

    else # there is no blast

      seqs.each do |s|
        exec_seq(s,nil)
      end

    end
  end

  def do_blasts(seqs)
    return []
  end

  #Initializes the structure stats  to the given key and value , only when it is neccesary, and increases its counter
  def add_stats(key,value)

    @stats[key]={} if @stats[key].nil?

    if @stats[key][value].nil?
      @stats[key][value] = 0
    end
    @stats[key][value] += 1

    # puts "@stats #{key} #{value}=#{ @stats[key][value]}"
  end

  #Initializes the structure stats  to the given key and value , only when it is neccesary, and increases its counter
  def add_text_stats(key,value,text)

    @stats[key]={} if @stats[key].nil?

    if @stats[key][value].nil?
      @stats[key][value] = []
    end

    @stats[key][value].push(text)

  end

  def overlapX?(r1_start,r1_end,r2_start,r2_end)
    # puts r1_start.class
    #     puts r1_end.class
    #     puts r2_start.class
    #     puts r2_end.class
    #     puts "-------"
    #puts "overlap? (#{r1_start}<=#{r2_end}) and (#{r1_end}>=#{r2_start})"
    return ((r1_start<=r2_end+1) and (r1_end>=r2_start-1) )
  end

  def merge_hits(hits,merged_hits,merged_ids=nil, merge_different_ids=true)
    # puts " merging ============"
    # hits.each do |hit|
    hits.sort{|h1,h2| (h1.q_end-h1.q_beg+1)<=>(h2.q_end-h2.q_beg+1)}.reverse_each do |hit|

      merged_ids.push hit.definition if !merged_ids.nil? && (! merged_ids.include?(hit.definition))
      # if new hit's position is already contained in hits, then ignore the new hit
      if merge_different_ids
        c=merged_hits.find{|c| overlapX?(hit.q_beg, hit.q_end,c.q_beg,c.q_end)}
      else
        # overlap with existent hit and same subject id
        c=merged_hits.find{|c| (overlapX?(hit.q_beg, hit.q_end,c.q_beg,c.q_end) && (hit.subject_id==c.subject_id))}
      end
      # puts " c #{c.inspect}"

      if (c.nil?)
        # add new contaminant
        #puts "NEW HIT #{hit.inspect}"
        merged_hits.push(hit.dup)
        #contaminants.push({:q_begin=>hit.q_beg,:q_end=>hit.q_end,:name=>hit.subject_id})
        #
      else

        # one is inside each other, just ignore
        if ((hit.q_beg>=c.q_beg && hit.q_end <=c.q_end) || (c.q_beg>=hit.q_beg && c.q_end <= hit.q_end))
          # puts "* #{hit.subject_id} inside #{c.subject_id}"
        else
          # merge with old contaminant
          # puts "#{hit.subject_id} NOT inside #{c.subject_id}"
          min=[c.q_beg,hit.q_beg].min
          max=[c.q_end,hit.q_end].max

          c.q_beg=min
          c.q_end=max


          # DONE para describir cada Id contaminante encontrado
          # puts "1 -#{c.subject_id}-   -#{hit.subject_id}-"
          c.subject_id += ' ' + hit.subject_id if (not c.subject_id.include?(hit.subject_id))
          # puts "2 -#{c.subject_id}-   -#{hit.subject_id}-"
          # puts "MERGE HIT (#{c.inspect})"
        end
        #
      end

    end
  end


  # def check_length_inserted(p_start,p_end,seq_fasta_length)
  #   min_insert_size  = @params.get_param('min_insert_size ').to_i
  #    v1= p_end.to_i
  #    v2= p_start.to_i
  #    v3= v1 - v2
  #    $LOG.debug "------ #{v3} ----"
  #
  #    res = true
  #    if ((v1 - v2 + 1) > (seq_fasta_length  - min_insert_size ))
  #      $LOG.debug "ERROR------ SEQUENCE IS NOT GOOD ----"
  #      res = false
  #    end
  #    return res
  # end
  #------------------------------------------
  # search a key into the sequence
  # Used: in class PluginLinker and PluginMid
  #-------------------------------------------
  # def search_key (seq,key_start,key_end)
  #   p_q_beg=0
  #   p_q_end=0
  #   if (seq.seq_fasta[key_start..key_end]==@params.get_param('key'))
  #      actions=[]
  #      #Add ActionKey and apply it to cut the sequence
  #
  #      type = "ActionKey"
  #
  #      p_q_beg,p_q_end=key_start,key_end
  #      a = seq.new_action(p_q_beg,p_q_end,type) # adds the actionKey/actionMid to the sequence
  #
  #      actions.push a
  #
  #      seq.add_actions(actions)  #apply cut to the sequence with the actions
  #    end
  #    return [p_q_beg,p_q_end]
  #
  # end

  def self.check_param(errors,params,param,param_class,default_value=nil, comment=nil)

    if !params.exists?(param)
      if !default_value.nil?
        params.set_param(param,default_value,comment)
      else
        errors.push "The param #{param} is required and thre is no default value available"
      end
    else
      s = params.get_param(param)
      # check_class=Object.const_get(param_class)
      begin
        case param_class
        when 'Integer'
          r = Integer(s)
        when 'Float'
          r = Float(s)
        when 'String'
          r = String(s)
        end

      rescue
        errors.push " The param #{param} is not a valid #{param_class}: ##{s}#"
      end
    end

  end



  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    return []
  end


  def self.graph_ignored?(stats_name)
    res = true

    if !self.ignored_graphs.include?(stats_name) && (self.valid_graphs.empty? || self.valid_graphs.include?(stats_name))
      res = false
    end

    return res
  end


  def self.plot_setup(stats_value,stats_name,x,y,init_stats,plot)
    return false
  end

  # automatically setup data
  def self.auto_setup(stats_value,stats_name,x,y)

    # res =false
    #
    # if !self.ignored_graphs.include?(stats_name) && (self.valid_graphs.empty? || self.valid_graphs.include?(stats_name))
    #
    #   res = true
    contains_strings=false

    stats_value.keys.each do |v|
      begin
        r=Integer(v)
      rescue
        contains_strings=true
        break
      end
    end

    # puts "#{stats_name} => #{contains_strings}"


    if !contains_strings
      stats_value.keys.each do |v|
        x.push v.to_i
      end

      x.sort!

      x.each do |v|
        y.push stats_value[v.to_s].to_i
      end

    else # there are strings in X
      x2=[]

      stats_value.keys.each do |v|
        x.push "\"#{v.gsub('\"','').gsub('\'','')}\""
        x2.push v
      end

      # puts ".#{x}."
      x2.each do |v|
        # puts ".#{v}."
        y.push stats_value[v.to_s]
      end
    end

    # return res
  end

  def self.get_graph_title(plugin_name,stats_name)
    return plugin_name + '/' +stats_name
  end

  def self.get_graph_filename(plugin_name,stats_name)
    return (plugin_name+ '_' +stats_name)
  end

  def self.ignored_graphs
    return []
  end

  def self.valid_graphs
    return []
  end


end
