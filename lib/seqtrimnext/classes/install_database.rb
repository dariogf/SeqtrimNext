require 'open-uri'

class InstallDatabase
  
  
  def initialize(type,db_path)
    
    
    types=['core','cont_bacteria','cont_fungi','cont_mitochondrias','cont_plastids','cont_ribosome','cont_viruses','adapters_illumina']
    
    if types.include?(type)
      
      if !File.exists?(db_path)
        FileUtils.mkdir_p(db_path)
      end
      
      remote_db_url="http://www.scbi.uma.es/downloads/#{type}_db.zip"
      local_path=File.join(db_path,'core_db.zip')
      puts "Install databases: #{type}"
    
      download_and_unzip(remote_db_url,local_path)
      
    else
      puts "Unknown database #{type}"
      puts "Available databases:"
      puts types.join("\n")
    end
  end
  
  def download_and_unzip(from_url,to_file)
    puts "Downloading databases from #{from_url} to #{to_file}"
    
    open(to_file, "w+") { |f| f.write(open(from_url).read)}
    
    puts "Unzipping #{to_file}"
    
    # unzip and remove
    # `cd #{File.dirname(to_file)};unzip #{to_file}; rm #{to_file}`
    `cd #{File.dirname(to_file)};unzip #{to_file}; rm #{to_file}`
    
  end
  
end