#================================================
# SCBI - dariogf <soporte@scbi.uma.es>
#------------------------------------------------
#
# Version: 0.1 - 04/2009
#
# Usage: require "utils/json_utils"
#
# Fasta utilities
#
# 
#
#================================================

module JsonUtils
  
  require 'json';
  
     
  def to_pretty_json
    return JSON.pretty_generate(self)
  end


  def from_json
       return JSON.parse(self)
  end
  
  # ===========================================
  
  #------------------------------------
  # get json data
  #------------------------------------
  def self.get_json_data(file_path)
    file1 = File.open(file_path)
    text = file1.read
    file1.close

    # wipe text
    text=text.grep(/^\s*[^#]/).to_s

    # decode json
    data = JSON.parse(text)

    return data
  end
  
end


