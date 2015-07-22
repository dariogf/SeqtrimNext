#########################################
# Author:: Almudena Bocinos Rioboo
# This class provided the methods to check if the necesary software is installed in the user system
 #########################################

class InstallRequirements 
  
 
  def initialize 
    @external_requirements = {}
    @ruby_requirements = {}  
    load_requirements
    
    
  end
  
   def check_install_requirements   
		  res = true
		  
		  errors = check_system_requirements
		  
		  if !errors.empty?
		  
		    $stderr.puts ' Unable to find these external requeriments:'
		    errors.each do |error|
		      $stderr.puts '   -' + error
		      res = false
		    end #end each
		    
		  end #end if

		  errors = check_ruby_requirements
		  if !errors.empty?
		    $stderr.puts ' Unable to find these Ruby requeriments:'
		    errors.each do |error|
		      $stderr.puts '   -' + error
		      res = false
		    end #end each
		  end #end if
		  
      return res
  end     


  
private
  
  def check_system_requirements
           
      errors=[]
        @external_requirements.each do |cmd,msg|
          if !system("which #{cmd} > /dev/null ")
            errors.push "It's necessary to install #{cmd}. " + msg
          end
        end
      
     return errors
  end
  
  def check_ruby_requirements(install=true)
      errors=[]

      
      
        @ruby_requirements.each do |cmd,msg|
          if !system("gem list #{cmd} | grep #{cmd} > /dev/null")
            if install
              puts "Are you sure you wan't to install #{cmd} gem? ([Y/n]):"
              res=stdin.readline
              if res.chomp.upcase!='N'
                system("echo gem install #{cmd}")
              end
            else
              errors.push "It's necessary to install #{cmd}. Issue a: gem install #{cmd} " + msg
            end
          end
        end
      
      return errors
  end
   
   
   
  # seqtrim's requirements are specified here
  def load_requirements
   
    @external_requirements['blastn']= "You need to install Blast+ 2.2.24 or greater and make sure it is available in your path (export PATH=$PATH:path_to_blast).\nYou can download it from ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/"
    @external_requirements['cd-hit-454']= "Download from http://code.google.com/p/cdhit/downloads/list"
    # @external_requirements['gnuplot']= "Download from http://www.gnuplot.info/download.html"
    
    # @external_requirements['pepe']= ""
    
                
    # @ruby_requirements = { 'n2array' => "" ,    
    @ruby_requirements['narray'] = ''
    # @ruby_requirements['gnuplot'] = ''
    @ruby_requirements['term-ansicolor'] = ''
    @ruby_requirements['xml-simple'] = ''
    @ruby_requirements['scbi_blast'] = ''
    @ruby_requirements['scbi_mapreduce'] = ''
    @ruby_requirements['scbi_fasta'] = ''
    @ruby_requirements['scbi_fastq'] = ''
    @ruby_requirements['scbi_plot'] = ''
    @ruby_requirements['scbi_math'] = ''
    # @ruby_requirements['scbi_fastq2'] = ''
    
  end # end  def
  
  def install
    
    # gem install gnuplot
    # gem install narray
    # gem install scbi_blast
    # gem install scbi_drb
    # gem install scbi_fasta
    # gem install scbi_fastq
    # gem install term-ansicolor
    # gem install xml-simple
    
    
  end
  
end
