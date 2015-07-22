######################################
# Author: Almudena Bocinos Rioboo
# This is the main class. 
######################################

require 'extract_stats'

require 'scbi_mapreduce'
require 'seqtrim_work_manager' 
require 'action_manager'

# SEQTRIM_VERSION_REVISION=27
# SEQTRIM_VERSION_STAGE = 'b'
# $SEQTRIM_VERSION = "2.0.0#{SEQTRIM_VERSION_STAGE}#{SEQTRIM_VERSION_REVISION}"

class Seqtrim
  
  # First of all, reads the file's parameters, where are the values of all parameters and the 'plugin_list'  that specifies the order of execution from the plugins. 
  #
  # Secondly, loads the plugins in a folder .
  #
  # Thirdly, checks if parameter's file have the number of parameters necessary for every plugin that is going to be executed.
  #
  # After that, creates a thread's pool of a determinate number of workers, e.g. 10 threads,
  # reads the sequences from files 'fasta' , until now without qualities,
  # and executes the plugins over the sequences in the pool of threads
  

  def get_custom_cdhit(cd_hit_input_file,params)
    cmd=''
    begin
      cdhit_custom_parameters=params.get_param('cdhit_custom_parameters').strip
      
      if !cdhit_custom_parameters.nil? and !cdhit_custom_parameters.empty?
        cmd = "cd-hit-454 -i #{cd_hit_input_file} -o clusters.fasta #{cdhit_custom_parameters} > cd-hit-454.out"
      end
    
    rescue Exception => exception #not an integer, send via ssh to other machine
      cmd=''
    end
    
    return cmd
  end
  
  def get_cd_hit_cmd(cd_hit_input_file,workers,init_file_path)
    
    num_cpus_cdhit=1
    cmd=''
    
    
    # if workers is an integer, reduce it by one in the server
		begin
		  Integer(workers)
		  num_cpus_cdhit = workers
		  cmd = "cd-hit-454 -i #{cd_hit_input_file} -o clusters.fasta -M #{num_cpus_cdhit*1000} -T #{num_cpus_cdhit} > cd-hit-454.out"
	    
	  rescue Exception => exception #not an integer, send via ssh to other machine
      # puts exception
	    worker_hash={};workers.map{|e| worker_hash[e] = (worker_hash[e]||0) +1}
	    
	    max_worker = worker_hash.sort_by{|k,v| -v}.first
	    puts "Found these workers: #{worker_hash.sort_by{|k,v| -v}}"
	    num_cpus_cdhit=max_worker[1]
	    
	    init=''
	    cd=''


	    cmd = "cd-hit-454 -i #{cd_hit_input_file} -o clusters.fasta -M #{num_cpus_cdhit*1000} -T #{num_cpus_cdhit} > cd-hit-454.out"
	    		    
      # worker is different to current machine, send over ssh
	    if max_worker[0]!= workers[0]
	       
		    
         if File.exists?(init_file_path)
           init=". #{init_file_path}; "
         end

        pwd=`pwd`.chomp

        cd =''

        if File.exists?(pwd)
          cd = "cd #{pwd}; "
        end
        cmd = "ssh #{max_worker[0]} \"#{init} #{cd} #{cmd}\""
	    end
    end
    
    
    
    return cmd
  end
  
  def check_global_params(params)
	  errors=[]
	  
    # check plugin list
    comment='Plugins applied to every sequence, separated by commas. Order is important'
   # default_value='PluginLowHighSize,PluginMids,PluginIndeterminations,PluginAbAdapters,PluginContaminants,PluginLinker,PluginVectors,PluginLowQuality'
#    params.check_param(errors,'plugin_list','String',default_value,comment)
    params.check_param(errors,'plugin_list','PluginList',nil,comment)

    
    comment='Should SeqTrimNext analysis be based on NGS? (if setting to false, a classic Sanger sequencing is considered)'
	  default_value='true'
	  params.check_param(errors,'next_generation_sequences','String',default_value,comment)

    
    comment='Remove duplicated (clonal) sequences (using CD-HIT 454)'
	  default_value='true'
	  params.check_param(errors,'remove_clonality','String',default_value,comment)

    comment='Custom parameters used by CD-HIT-454 (leave empty to let seqtrimnext decide). Execute "cd-hit-454 help" in command line to see a list of parameters'
	  default_value=''
	  params.check_param(errors,'cdhit_custom_parameters','String',default_value,comment)

    comment='Generate initial stats'
	  default_value='true'
	  params.check_param(errors,'generate_initial_stats','String',default_value,comment)

		comment='Minimum insert size for every trimmed sequence'
		default_value = 40
		params.check_param(errors,'min_insert_size_trimmed','Integer',default_value,comment)
		
		comment='Minimum insert size for each end of paired-end reads; true paired-ends have both single-ends longer than this value'
		default_value = 40
		params.check_param(errors,'min_insert_size_paired','Integer',default_value,comment)
		

		comment='Do not reject unexpectedly long sequences found in the raw data'
		default_value='true'
		params.check_param(errors,'accept_very_long_sequences','String',default_value,comment)

		comment='Seqtrim version'
		default_value=Seqtrimnext::SEQTRIM_VERSION
		params.check_param(errors,'seqtrim_version','String',default_value,comment)

		
		if !errors.empty?
          $LOG.error 'Please, define the following global parameters in params file:'
          errors.each do |error|
            $LOG.error '   -' + error
          end #end each
        end #end if

		return errors.empty?
		
  end
  
  
  
  def initialize(options)
    # ,options[:fasta],options[:qual],,,,
    params_path=options[:template]
    
    ip=options[:server_ip]
    port=options[:port]
    workers=options[:workers]
    only_workers=options[:only_workers]
    chunk_size = options[:chunk_size]
    use_json = options[:json]
    
    # check for checkpoint
    
    if File.exists?(ScbiMapreduce::CHECKPOINT_FILE)
      if !options[:use_checkpoint]
        STDERR.puts "ERROR: A checkpoint file exists, either delete it or provide -C flag to use it"
        exit
      end
    end
    
       
    
    # it is the server part
  if !only_workers then

    cd_hit_input_file = nil
    
    # TODO - FIX seqtrim to not iterate two times over input, so STDIN can be used
    sequence_readers=[]

    # open sequence reader and expand input files paths
    if options[:fastq]
      
      # choose fastq quality format
      format=:sanger
      
      case options[:format]
      when 'sanger'
        format = :sanger
      when 'illumina15'
        format = :ilumina
      when 'illumina18'
        format = :sanger
      end
      
      seqs_path=''
      
      $LOG.info("Used FastQ format for input files: #{format}")
      # iterate files
      options[:fastq].each do |fastq_file|
        
        if fastq_file=='-'
          seqs_path = STDIN
        else
          seqs_path = File.expand_path(fastq_file)
        end
        
        sequence_readers << FastqFile.new(seqs_path,'r',format, true)
        
      end
      
      cd_hit_input_file = seqs_path
      
    else

      seqs_path = File.expand_path(options[:fasta])
      cd_hit_input_file = seqs_path
      
      qual_path =  File.expand_path(options[:qual]) if qual_path
      sequence_readers << FastaQualFile.new(options[:fasta],options[:qual],true)

    end

   
    $LOG.info "Loading params"
    # Reads the parameter's file
    params = Params.new(params_path)

    $LOG.info "Checking global params"
    if !check_global_params(params)
    		exit
    end
                                   
    # Load actions
    $LOG.info "Loading actions"
    action_manager = ActionManager.new()

		# load plugins 
    plugin_list = params.get_param('plugin_list') # puts in plugin_list the plugins's array
    $LOG.info "Loading plugins [#{plugin_list}]"    
    
    
    plugin_manager = PluginManager.new(plugin_list,params) # creates an instance from PluginManager. This must storage the plugins and load it
     
     
     
		# load plugin params
    $LOG.info "Check plugin params"
    if !plugin_manager.check_plugins_params(params) then
	    	$LOG.error "Plugin check failed"

	    	# save used params to file
        params.save_file('used_params.txt')

      exit
    end
    
    if !Dir.exists?(OUTPUT_PATH)
      Dir.mkdir(OUTPUT_PATH)
    end

    # Extract global stats
    if params.get_param('generate_initial_stats')=='true'
      $LOG.info "Calculatings stats"
      ExtractStats.new(sequence_readers,params)
    else
      $LOG.info "Skipping calculatings stats phase."
    end
    
    
    # save used params to file
    params.save_file(File.join(OUTPUT_PATH,'used_params.txt'))
    
    piro_on = (params.get_param('next_generation_sequences')=='true')

      params.load_mids(params.get_param('mids_db'))
      params.load_ab_adapters(params.get_param('adapters_ab_db'))
      params.load_adapters(params.get_param('adapters_db'))
      params.load_linkers(params.get_param('linkers_db'))
      
      #execute cd-hit
      if params.get_param('remove_clonality')=='true'
        cmd=get_custom_cdhit(cd_hit_input_file,params)
        if cmd.empty?
          cmd=get_cd_hit_cmd(cd_hit_input_file,workers,$SEQTRIMNEXT_INIT)
        end
        
        $LOG.info "Executing cd-hit-454: #{cmd}"
        
        if !File.exists?('clusters.fasta.clstr')
				  system(cmd)
        end
        
        if File.exists?('clusters.fasta.clstr')
	        params.load_repeated_seqs('clusters.fasta.clstr')
        else
          $LOG.error("Exiting due to not found clusters.fasta.clstr. Maybe cd-hit failed. Check cd-hit.out")
          exit
        end
	    end
      
			
		############ SCBI DRB ###########
#			port = 50000
#			ip = "10.250.255.6"
#			port = 50000
#			ip = "localhost"
#
#			workers=20
#			only_workers=false
				# launch work manager
	

  end # end only_workers

			custom_worker_file = File.join(File.dirname(__FILE__), 'em_classes','seqtrim_worker.rb')
      
			$LOG.info "Workers:\n#{workers}"
			
      if only_workers then
        
        worker_launcher = ScbiMapreduce::WorkerLauncher.new(ip,port, workers, custom_worker_file, STDOUT)
        worker_launcher.launch_workers_and_wait
      else
  			$LOG.info 'Starting server'
      	        
 				SeqtrimWorkManager.init_work_manager(sequence_readers, params,chunk_size,use_json,options[:skip_output],options[:write_in_gzip])
				
        begin
  				cpus=1
				
  				if RUBY_PLATFORM.downcase.include?("darwin")
            cpus=`hwprefs -cpu_count`.chomp.to_i
  			  else
  			    cpus=`grep processor /proc/cpuinfo |wc -l`.chomp.to_i
  		    end
        rescue
          cpus=1
        end
				
        # if workers is an integer, reduce it by one (because of the server)
				begin
				  Integer(workers)
				  if workers>1 && workers<cpus
				    workers-=1
			    end
			  rescue
				  if workers.count>1 && workers.count<cpus
			      workers.shift
			    end
		    end
				
				# launch processor server passing the ip, port and all required params
        # server = Server.new(ip,port, workers, SeqtrimWorkManager,custom_worker_file, STDOUT,File.join($SEQTRIM_PATH,'init_env'))
        # server = ScbiMapreduce::Manager.new(ip,port, workers, SeqtrimWorkManager,custom_worker_file, STDOUT,'~/.seqtrimnext')
				server = ScbiMapreduce::Manager.new(ip,port, workers, SeqtrimWorkManager,custom_worker_file, STDOUT,$SEQTRIMNEXT_INIT)
				server.chunk_size=chunk_size
        server.checkpointing=true
        server.keep_order=true
        server.retry_stuck_jobs=true
				server.start_server
        
        # close sequence reader
				sequence_readers.each do |file|
				  file.close
				end
				
				$LOG.info 'Closing server'
			end
			
			############ SCBI DRB ###########

  end
  
end # Seqtrim class
