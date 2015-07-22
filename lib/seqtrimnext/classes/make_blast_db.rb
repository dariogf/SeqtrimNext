
class MakeBlastDb
  
def initialize(dir)

  @db_folder = dir
  @status_folder = File.join(@db_folder,'status_info')
  @formatted_folder = File.join(@db_folder,'formatted')
  
  update_dbs
end

def catFasta(path_start,path_end)
  $LOG.debug("Cat of #{path_start}")
  
  # system("cat #{path_start} > #{path_end}")
  system("cat /dev/null > #{path_end}")
       
  system("for i in `find #{path_start} -type f ! -name '.*'`; do echo cat of $i; cat $i >> #{path_end}; echo \"\n\" >> #{path_end}; done")
  
end

def dirEmpty?(path_db)

  folder2=Dir.open("#{path_db}")
  
  ignore = ['.','..','.DS_Store']
  
  res = folder2.entries - ignore
  
  return res.empty?  
end

  def merge_db_files(path_db, db_name, formatted_folder)
		if !dirEmpty?(path_db)
		  #hay que hacer el cat solo cuando cambian los ficheros que hay en subfolder1
		  formatted_file = File.join(formatted_folder, db_name+'.fasta')
		  catFasta(File.join(path_db),formatted_file)
		end
  end

def self.format_db(path_db, db_name, formatted_folder)

    #hay que hacer el cat solo cuando cambian los ficheros que hay en subfolder1
    formatted_file = File.join(formatted_folder, db_name+'.fasta')
		cmd = "makeblastdb -in #{formatted_file} -parse_seqids -dbtype nucl >> logs/formatdb.log"
		system(cmd)
		$LOG.info(cmd)

end

#---------------------------------------------------------------------------------------------------
# Check if files for DataBase have been updated, and only when that has happened, makeblastdb will run   
# Consideres the next directories structure:     
# 
#     @dir is the main directory                               
#     @dir/folder0  is the directoy where will be storaged the DB created/updated
#     @dir/folder0/subfolder1 is where are storaged all the fasta files of the type subfolder1 
#     @dir/update is where register the log for each subfolder1, to check if DB has been updated
#---------------------------------------------------------------------------------------------------
def update_dbs

  FileUtils.mkdir_p(@status_folder)
  FileUtils.mkdir_p(@formatted_folder)
     
  ignore_folders=['.','..','status_info','formatted']

	$LOG.info("Checking Blast databases at #{@db_folder} for updates")
 
  dbs_folder=Dir.open(@db_folder)
  
  #if all file_update.entries is in folder1.entries then cat db/* > DB , make blast, guardar ls nuevo 
  dbs_folder.entries.each do |db_name|
  	
    db_folder=File.join(@db_folder,db_name)
		if (!ignore_folders.include?(db_name) and File.directory?(db_folder))
 			
 			#puts "Checking #{db_name} in #{db_folder}"
 	
     #path_db = File.join(@dir,db_folder)
			
			# set status files    
    	new_status_file = File.join(@status_folder,'new_'+db_name+'.txt')
    	old_status_file = File.join(@status_folder,'old_'+db_name+'.txt')
    
      cmd = "ls -lR #{db_folder} > #{new_status_file}"
      $LOG.debug(cmd)
      # list new status tu new_status_file
      # system("ls -lR #{File.join(db_folder,'*')} > #{new_status_file}")
      system(cmd)
      
      # if new and old statuses files changed, then reformat
      if (!(File.exists?(old_status_file)) || !system("diff -q #{new_status_file} #{old_status_file} > /dev/null ") || !File.exists?(File.join(@formatted_folder,db_name+'.fasta')))
  					
						$LOG.info("Database #{db_name} modified. Merging and formatting")
						
  					merge_db_files(db_folder,db_name,@formatted_folder)
  										    
            MakeBlastDb.format_db(db_folder,db_name,@formatted_folder)
            
            # rename new_status_file to replace the old one
            system("mv #{new_status_file} #{old_status_file}")
       end
    	
    end
    
  end #end folder1.entries
 
end

end


