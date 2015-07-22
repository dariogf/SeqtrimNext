
#List all entries in a DB, by name
#
#list all DB names if db is ALL

class ListDb

def initialize(path,db)
    
		filename=File.join(path,'formatted',db)
	  if File.exists?(filename)
	  
				f = File.open(filename)
		
				f.grep(/^>(.*)$/) do |line|
					puts $1
				end
				f.close
		else
				puts "File #{filename} doesn't exists"
				puts ''
				puts "Available databases:"
				puts '-'*20
				d=Dir.glob(File.join(path,'formatted','*.fasta'))
   	  	d.entries.map{|e| puts File.basename(e)}

				
#		cmd= "grep '^>' #{File.join(path,'formatted',db+'.fasta')}"
		
#		system(cmd)
	  end

end

def self.list_databases(path)
  res = []
  
  if File.exists?(path)
    d=Dir.glob(File.join(path,'formatted','*.fasta'))
  
	  res = d.entries.map{|e| File.basename(e)}
  end
  return res
	
	
end


end
