
#finds the classes that were in the folder 'classes'

# ROOT_PATH=File.dirname(File.dirname(File.dirname(__FILE__)))
#
# $: << File.expand_path(File.join(ROOT_PATH, 'classes'))
# $: << File.expand_path(File.join(ROOT_PATH, 'classes','blast'))
#
# #finds the classes that were in the folder 'plugins'
# $: << File.expand_path(File.join(ROOT_PATH, 'plugins'))
#
# #finds the classes that were in the folder 'plugins'
# $: << File.expand_path(File.join(ROOT_PATH, 'actions'))
#
# #finds the classes that were in the folder 'utils'
# $: << File.expand_path(File.join(ROOT_PATH, 'utils'))
#
# $: << File.expand_path(File.join(ROOT_PATH, 'classes','em_classes'))
#
# $: << File.expand_path(ROOT_PATH)

# $: << File.expand_path('~/progs/ruby/gems/seqtrimnext/lib/')
# $: << File.expand_path('~/progs/ruby/gems/scbi_mapreduce/lib')

require 'seqtrimnext'

$SEQTRIM_PATH = ROOT_PATH


if ENV['BLASTDB']# && Dir.exists?(ENV['BLASTDB'])
  $FORMATTED_DB_PATH = ENV['BLASTDB']
  $DB_PATH = File.dirname($FORMATTED_DB_PATH)
else
  $FORMATTED_DB_PATH = File.expand_path(File.join(ROOT_PATH, "DB",'formatted'))
  $DB_PATH = File.expand_path(File.join(ROOT_PATH, "DB"))
end

ENV['BLASTDB']=$FORMATTED_DB_PATH

OUTPUT_PATH='output_files'

puts "FORMATTED_DB_BLAST in workers: #{$FORMATTED_DB_PATH}"


require 'scbi_mapreduce'
require 'params'
require 'action_manager'
require 'plugin_manager'
# require 'sequence_with_action'
#
require 'scbi_fastq'
require 'sequence_group'

class SeqtrimWorker <  ScbiMapreduce::Worker

  def process_object(obj)

    running_seqs=SequenceGroup.new(obj.flatten)

    # execute plugins
    @plugin_manager.execute_plugins(running_seqs)

    # add output data
    add_output_data(running_seqs)

    return running_seqs
  end

  def receive_initial_config(obj)

    # Reads the parameters
    $WORKER_LOG.info "Params received"
    #				@params = Params.new(params_path)
    @params = obj
    @tuple_size=@params.get_param('tuple_size')

    @use_qual=@params.get_param('use_qual')
    @use_json=@params.get_param('use_json')
  end

  def starting_worker

    # $WORKER_LOG.level = Logger::ERROR
    $WORKER_LOG.level = Logger::WARN
    #$WORKER_LOG.level = Logger::INFO
    $WORKER_LOG.info "Loading actions"

    @action_manager = ActionManager.new

    $WORKER_LOG.info "Loading plugins"
    @plugin_list = @params.get_param('plugin_list') # puts in plugin_list the plugins's array
    $WORKER_LOG.info "PLUGIN LIST:" + @plugin_list

    @plugin_manager = PluginManager.new(@plugin_list,@params) # creates an instance from PluginManager. This must storage the plugins and load it

  rescue Exception => e
    puts (e.message+ e.backtrace.join("\n"))

  end


  def closing_worker

  end


  def add_output_data(obj)
    obj.output_text=[]

    if @tuple_size>1
      obj.each_slice(@tuple_size) do |seqs|

        write_seq_to_files_tuple(obj.output_files,seqs, obj.stats)

        seqs.each do |seq|
          obj.output_text << seq.to_text
        end
      end

    else
      obj.each do |seq|
        write_seq_to_files_normal(obj.output_files,seq, obj.stats)
        obj.output_text << seq.to_text
      end
    end

    # @remove seqs since they are not needed anymore to write output files
    obj.remove_all_seqs
  end

  def add_stat(stats,key,subkey,value,count=1)

    stats[key]={} if !stats[key]
    stats[key][subkey]={} if !stats[key][subkey]
    stats[key][subkey][value]=0 if !stats[key][subkey][value]

    stats[key][subkey][value]+=count
  end

  def write_seq_to_files_tuple(files,seqs, stats)

    
    seq1=seqs[0]
    seq2=seqs[1]
    
    dir_name,file_name,priority=seq1.get_file_tag_path
    dir_name2,file_name2,priority2=seq2.get_file_tag_path
    
    # both paired sequences must go in same file, there are priorities
    if (dir_name!=dir_name2) || (file_name!=file_name2)
      if priority2>priority
        dir_name=dir_name2
        file_name=file_name2
      end
    end
    
    # get current inserts
    inserts1 = seq1.get_inserts
    inserts2 = seq2.get_inserts

    # qualities are optional
    if @use_qual
      qual_inserts1 = seq1.get_qual_inserts
      qual_inserts2 = seq2.get_qual_inserts
    end
    
    
    
    # save json if necessary
    if @use_json
      json_file(files)<< seq1.to_json
      json_file(files)<< seq2.to_json
    end

    # find mids
    mid1 = seq1.get_actions(ActionMid).first
    mid2 = seq2.get_actions(ActionMid).first
    
    
    if !inserts1.empty? && !inserts2.empty? # both have inserts
      # save_two_inserts(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
      save_two_inserts_tuple(files,seq1,seq2, stats,inserts1,inserts2,qual_inserts1,qual_inserts2,mid1,dir_name,file_name)
    else
      save_rejected_empty_or_single(files,seq1, stats,inserts1,qual_inserts1,mid1,dir_name,file_name)
      save_rejected_empty_or_single(files,seq2, stats,inserts2,qual_inserts2,mid2,dir_name,file_name)
    end
    
  end
  
  def save_two_inserts_tuple(files,seq1,seq2, stats,inserts1,inserts2,qual_inserts1,qual_inserts2,mid,dir_name,file_name)
    
    add_stat(stats,'sequences','count','output_seqs_paired')
    add_stat(stats,'sequences','count','output_seqs_paired')

    mid_id,mid_message=get_mid_message(mid)

    # save left read
    n="#{seq1.seq_name}"
    c=seq1.get_comment_line # "template=#{seq1.seq_name} dir=R library=#{mid_id}"
    f=inserts1[0]#.reverse.tr('actgACTG','tgacTGAC')
    q=[]
    if @use_qual
      q=qual_inserts1[0] #.reverse
    end
    
    paired_file_ilu1(files,dir_name,file_name)<<FastqFile.to_fastq(n,f,q,c)
    
    # save right read
    n="#{seq2.seq_name}"
    c=seq2.get_comment_line # "template=#{seq2.seq_name} dir=F library=#{mid_id}"
    f=inserts2[0]
    q=[]
    if @use_qual
      q=qual_inserts2[0]
    end

    paired_file_ilu2(files,dir_name,file_name)<<FastqFile.to_fastq(n,f,q,c)
    
  end
  
  
  def save_rejected_empty_or_single(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
    if (seq.seq_rejected) # save to rejected sequences
      save_rejected_seq(files,seq, stats)
    elsif (inserts.empty?)  #sequence with no inserts
      save_empty_insert(files,seq, stats)
    elsif (inserts.count == 1) # sequence with one insert
      save_one_insert(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
    end
  end
  
  
  #  SAVE NORMAL ===============================
  def save_rejected_seq(files,seq, stats)
    # message = seq.seq_rejected_by_message
    message= seq.get_comment_line
    rejected_output_file(files)<<('>'+seq.seq_name+ ' ' + message)

    add_stat(stats,'sequences','rejected',seq.seq_rejected_by_message)
    add_stat(stats,'sequences','count','rejected')
  end
  
  def save_empty_insert(files,seq, stats)
    seq.seq_rejected=true
    seq.seq_rejected_by_message='short insert'

    message = 'No valid inserts found'

    rejected_output_file(files)<<('>'+seq.seq_name+ ' ' + message)

    add_stat(stats,'sequences','rejected',message)
    add_stat(stats,'sequences','count','rejected')
    
  end
  
  def get_mid_message(mid)
    if (mid.nil? || (mid.message=='no_MID') ) # without mid
      mid_id = 'no_MID'
      mid_message = ' No MID found'
    else
      mid_id = mid.tag_id
      mid_message=''
      if mid_id != mid_message
        mid_message = ' '+mid.message
      end
    end
    return mid_id,mid_message
  end
  
  def save_two_inserts(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
    add_stat(stats,'sequences','count','output_seqs_paired')

    mid_id,mid_message=get_mid_message(mid)

    # save left read
    n="#{seq.seq_name}_left"
    c="template=#{seq.seq_name} dir=R library=#{mid_id} #{seq.get_comment_line}"
    f=inserts[0].reverse.tr('actgACTG','tgacTGAC')
    q=[]
    if @use_qual
      q=qual_inserts[0].reverse
    end
    
    paired_file(files,dir_name,file_name)<<FastqFile.to_fastq(n,f,q,c)
    
    # save right read
    n="#{seq.seq_name}_right"
    c="template=#{seq.seq_name} dir=F library=#{mid_id}  #{seq.get_comment_line}"
    f=inserts[1]
    q=[]
    if @use_qual
      q=qual_inserts[1]
    end

    paired_file(files,dir_name,file_name)<<FastqFile.to_fastq(n,f,q,c)
    
  end
  
  def save_one_insert(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
    mid_id,mid_message=get_mid_message(mid)

    # save fasta and qual in no MID file
    has_low_complexity = seq.get_actions(ActionLowComplexity)

    if has_low_complexity.empty?
      add_stat(stats,'sequences','count','output_seqs')

      fasta_file=sequence_file(files,dir_name,file_name)
      sff_file=sffinfo_file(files,dir_name,file_name)
    else
      add_stat(stats,'sequences','count','output_seqs_low_complexity')

      fasta_file=low_complexity_file(files,dir_name,file_name)
      sff_file=low_sffinfo_file(files,dir_name,file_name)
    end

    q=[]
    if @use_qual
      q=qual_inserts[0]
    end

    n=seq.seq_name
    c=mid_message

    seq_comments=seq.get_comment_line
    if !seq_comments.strip.empty?
      c=seq_comments + c
    end

    f=inserts[0]

    fasta_file << FastqFile.to_fastq(n,f,q,c)

    inserts_pos = seq.get_actions(ActionInsert)

    sff_file<< "#{n} #{inserts_pos[0].start_pos+1} #{inserts_pos[0].end_pos+1}"
    
    
  end


  def write_seq_to_files_normal(files,seq, stats)

    # puts stats.to_json

    dir_name,file_name,priority=seq.get_file_tag_path
    # puts File.join(dir_name,'sequences_'+file_name)

    # get current inserts
    inserts = seq.get_inserts

    # qualities are optional
    if @use_qual
      qual_inserts = seq.get_qual_inserts
    end

    # save json if necessary
    if @use_json
      json_file(files)<< seq.to_json
    end

    # find mids
    mid = seq.get_actions(ActionMid).first


    if (seq.seq_rejected) # save to rejected sequences
      save_rejected_seq(files,seq, stats)
      
    elsif (inserts.empty?)  #sequence with no inserts
      save_empty_insert(files,seq, stats)
      
    elsif (inserts.count == 2) # sequence with two inserts  = PAIRED SEQUENCES
      save_two_inserts(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
      
    elsif (inserts.count == 1) # sequence with one insert
      save_one_insert(files,seq, stats,inserts,qual_inserts,mid,dir_name,file_name)
    end

  end
  
  
  


  # ACCESS TO FILES

  def json_file(files)
    return get_file(files,File.join(OUTPUT_PATH,'results.json'))
  end

  def rejected_output_file(files)
    return get_file(files,File.join(OUTPUT_PATH,'rejected.txt'))
  end


  def sequence_file(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'sequences_'+file_name+'.fastq'))
  end

  def paired_file(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'paired_'+file_name+'.fastq'))
  end
  
  def paired_file_ilu1(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'paired_1_'+file_name+'.fastq'))
  end

  def paired_file_ilu2(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'paired_2_'+file_name+'.fastq'))
  end
  

  def low_complexity_file(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'low_complexity_'+file_name+'.fastq'))
  end

  def sffinfo_file(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'sff_info_'+file_name+'.txt'))
  end

  def low_sffinfo_file(files, dir_name, file_name)
    return get_file(files,File.join(OUTPUT_PATH,dir_name,'low_complexity_sff_info_'+file_name+'.txt'))
  end

  def get_file(files,fn)
    res=files[fn]

    if !res
      files[fn]=[]
      res=files[fn]
    end

    return res
  end

end
