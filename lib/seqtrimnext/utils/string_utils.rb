
class String
  
   def integer?
                     
     res = true
      
     begin
       r=Integer(self)
     rescue
       res=false
     end
     
     return res
   end
   
   def decamelize 
        self.to_s. 
          gsub(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'). 
          gsub(/([a-z]+)([A-Z\d])/, '\1_\2'). 
          gsub(/([A-Z]{2,})(\d+)/i, '\1_\2'). 
          gsub(/(\d+)([a-z])/i, '\1_\2'). 
          gsub(/(.+?)\&(.+?)/, '\1_&_\2'). 
          gsub(/\s/, '_').downcase 
   end
  
end

class File
  
  def self.is_zip?(file_path)
    res=false
    begin
      f=File.open(file_path,'rb')
      head=f.read(4)
      f.close
      res=(head=="PK\x03\x04")
    rescue
      res=false
    end
    
    return res
  end
  
  def self.unzip(file_path)
    unzipped=`unzip "#{file_path}"`
    file_list = unzipped.split("\n")
    list=[]
    
    # select only the files, not folders
    list=file_list.select{|e| e=~/inflating/}.map{|e| e.gsub('inflating:','').strip}
    
    return list
  end
  
end