require 'scbi_fasta'
require 'scbi_fastq'
# require 'work_manager'
require 'graph_stats'
require 'sequence_with_action'
require 'sequence_group'

# OUTPUT_PATH='output_files'
STATS_PATH=File.join(OUTPUT_PATH,'stats.json')
# TODO - Pasar secuencias en grupos, y hacer blast en grupos de secuencias.



class SeqtrimWorkManager < ScbiMapreduce::WorkManager

  def self.init_work_manager(sequence_readers, params, chunk_size = 100, use_json=false, skip_output=false, write_in_gzip=true)
    @@full_stats={}
    @@params= params
    @@exit = false
    @@exit_status=0

    @@ongoing_stats={}
    @@ongoing_stats[:sequence_count] = 0
    @@ongoing_stats[:smallest_sequence_size] = 900000000000000
    @@ongoing_stats[:biggest_sequence_size] = 0

    @@skip_output=skip_output
    @@write_in_gzip=write_in_gzip

    @@chunk_size = chunk_size

    checkpoint_exists=File.exists?(ScbiMapreduce::CHECKPOINT_FILE)

    # @@use_qual = !qual_path.nil? and File.exists?(qual_path)
    @@open_mode='w'
    if checkpoint_exists
      @@open_mode = 'a'
    end

    #open input file
    @@sequence_readers=sequence_readers

    # @@use_qual = @@fqr.with_qual?
    # @@use_json = use_json

    @@params.set_param('use_qual',@@sequence_readers.first.with_qual?)
    @@params.set_param('use_json',use_json)
    @@params.set_param('tuple_size',@@sequence_readers.count)

    @@use_json=use_json

    @@sequence_readers.each do |sequence_reader|
      sequence_reader.rewind
    end

    # open output files

    if !Dir.exists?(OUTPUT_PATH)
      Dir.mkdir(OUTPUT_PATH)
    end

    @@files={}

    # @@rejected_output_file=File.open(File.join(OUTPUT_PATH,'rejected.txt'),@@open_mode)

    # seqs_with_errors
    @@errors_file=File.open('errors.txt',@@open_mode)

    if @@use_json
      @@json_output=File.open('results.json',@@open_mode)
    end

    @@json_separator=''

    @@paired_output_files={}

    @@sequences_output_files={}

    @@low_complexity_output_files={}

    @@sffinfo_files={}

    @@low_sffinfo_files={}

    @@tuple_id=0

  end

  def self.exit_status
    return @@exit_status
  end

  def self.end_work_manager

    # if initial files doesn't exists, create it
    if !File.exists?(File.join(OUTPUT_PATH,'initial_stats.json'))
      File.open(File.join(OUTPUT_PATH,'initial_stats.json'),'w') do |f|
        f.puts JSON.pretty_generate(@@ongoing_stats)
      end
    end

    # load stats
    #r=File.read(STATS_PATH)
    #stats=JSON::parse(r)

    stats=@@full_stats

    # make graphs
    gs=GraphStats.new(stats)

    #close all files
    if @@use_json
      @@json_output.close
    end
    @@errors_file.close

    @@files.each do |k,file|
      file.close
    end

  end

  def self.global_error_received(error_exception)
    $LOG.error "Global error:\n" + error_exception.message + ":\n" +error_exception.backtrace.join("\n")
    @@errors_file.puts "Global error:\n" + error_exception.message + ":\n" +error_exception.backtrace.join("\n")
    @@errors_file.puts "="*60
    @@exit_status=-1
    SeqtrimWorkManager.controlled_exit
  end

  def self.work_manager_finished
    @@full_stats['scbi_mapreduce']=@@stats

    puts "FULL STATS:\n" +JSON.pretty_generate(@@full_stats)

    # create stats file
    f = File.open(STATS_PATH,'w')
    f.puts JSON.pretty_generate(@@full_stats)
    f.close
  end

  def error_received(worker_error, obj)
    @@errors_file.puts "Error while processing object #{obj.inspect}\n" + worker_error.original_exception.message + ":\n" +worker_error.original_exception.backtrace.join("\n")
    @@errors_file.puts "="*60
    @@exit_status=-1
    SeqtrimWorkManager.controlled_exit

  end

  def too_many_errors_received
    $LOG.error "Too many errors: #{@@error_count} errors on #{@@count} executed sequences, exiting before finishing"
    @@exit_status=-1
  end

  def worker_initial_config
    return @@params
  end

  def load_user_checkpoint(checkpoint)
    # load full_stats from file !!!!!!!!!!!!!

    if File.exists?(STATS_PATH)

      # load stats
      text = File.read(STATS_PATH)

      # wipe text
      # text=text.grep(/^\s*[^#]/).to_s

      # decode json
      @@full_stats = JSON.parse(text)
    end

    # reset count stats since they are repeated by checkpointing

    # {
    #   "sequences": {
    #   "count": {
    #     "input_count": 1600,
    #     "output_seqs": 933,
    #     "rejected": 67
    #   },
    #   "rejected": {
    #     "short insert": 39,
    #     "contaminated": 26,
    #     "unexpected vector": 2
    #   }
    # }
    # }

    if @@full_stats['sequences']
      if @@full_stats['sequences']['count']
        # set input count to 0
        @@full_stats['sequences']['count']['input_count']=0

        # do not remove outputseqs
        # @@full_stats['sequences']['count']['output_seqs']=0
      end

      # remove rejected due to repetitions from rejected count
      if @@full_stats['sequences']['rejected']

        # it there are repeated
        if (@@full_stats['sequences']['rejected']['repeated'])

          # if repeated count > 0 and there count exists
          if (@@full_stats['sequences']['rejected']['repeated'] > 0) and @@full_stats['sequences']['count']

            # discount repeated from rejected, since they are going to be added again by checkout process
            @@full_stats['sequences']['count']['rejected'] -= @@full_stats['sequences']['rejected']['repeated']
          end

          # set repeated to 0
          @@full_stats['sequences']['rejected']['repeated']=0
        end
      end
    end


    # puts "Loaded Stats"
    # puts "FULL STATS:\n" +JSON.pretty_generate(@@full_stats)

    # TODO - remove sequences from rejected file that were added by cloned

    super
    # return checkpoint
  end

  def save_user_checkpoint

    f = File.open(STATS_PATH,'w')
    f.puts JSON.pretty_generate(@@full_stats)
    f.close

  end


  # read a work that will not be processed, only to skip until checkpoint
  def trash_checkpointed_work
    warn "Deprecated: trash_checkpointed_work was deprecated, it is automatic now"
  end

  def get_next_seq_from_file(file)
    # find a valid and no repeated sequence in file
    begin

      n,f,q,c = file.next_seq

      if !n.nil? && @@params.repeated_seq?(n)
        @@full_stats.add_stats({'sequences' => {'count' => {'rejected' => 1}}})
        @@full_stats.add_stats({'sequences' => {'rejected' => {'repeated' => 1}}})

        get_file(File.join(OUTPUT_PATH,'rejected.txt')).puts('>'+n+ ' repeated')

      end

      if !n.nil?
        @@ongoing_stats[:sequence_count] += 1
        @@ongoing_stats[:smallest_sequence_size] = [f.size, @@ongoing_stats[:smallest_sequence_size]].min
        @@ongoing_stats[:biggest_sequence_size] = [f.size, @@ongoing_stats[:smallest_sequence_size]].max

        @@full_stats.add_stats({'sequences' => {'count' => {'input_count' => 1}}})
      end

    end while (!n.nil? && @@params.repeated_seq?(n))

    return n,f,q,c

  end

  def next_work

    if @@exit
      return nil
    end

    tuple=[]
    order_in_tuple=0

    @@tuple_id += 1
    tuple_size=@@sequence_readers.count

    @@sequence_readers.each do |sequence_reader|
      n,f,q,c = get_next_seq_from_file(sequence_reader)

      if !n.nil?
        seq=SequenceWithAction.new(n,f.upcase,q,c)
        seq.tuple_id=@@tuple_id
        seq.order_in_tuple=order_in_tuple
        seq.tuple_size=tuple_size
        tuple << seq
        order_in_tuple+=1
      end

    end

    if tuple_size>1
      # check duplicated names
      names = tuple.map{|s| s.seq_name}
      
      if names.uniq.count!=tuple_size
        # puts "NAMES EQUAL IN TUPLE"
        tuple.each_with_index do |seq,i|
          # puts seq.class # seq_name
          seq.seq_name = "#{seq.seq_name}/#{i+1}"
        end
      end
    end

    # tuple is complete
    if tuple.count==tuple_size
      return tuple
    else
      return nil
    end

  end


  def work_received(obj)

    res = obj

    # collect stats
    @@full_stats.add_stats(obj.stats)

    # print output in screen
    if !@@skip_output
      puts obj.output_text
    end

    # save results to files
    save_files(obj)

  end

  def save_files(obj)
    files=obj.output_files
    files.each do |file_name,content|
      f=get_file(file_name)
      f.puts content
    end
  end

  def get_file(file_name)
    res_file = @@files[file_name]

    # if file is not already open, create it
    if res_file.nil?
      # create dir if necessary
      dir = File.dirname(file_name)
      if !File.exists?(dir)
        FileUtils.mkdir_p(dir)
      end

      # open file
      if @@write_in_gzip && file_name.upcase.index('.FASTQ')
        file=File.open(file_name+'.gz',@@open_mode)
        res_file=Zlib::GzipWriter.new(file)
      else
        res_file=File.open(file_name,@@open_mode)
      end

      # save it in hash for next use
      @@files[file_name]=res_file
    end

    return res_file
  end


end
