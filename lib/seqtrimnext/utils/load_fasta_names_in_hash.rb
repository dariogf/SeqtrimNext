#================================================
# SCBI - dariogf <soporte@scbi.uma.es>
#------------------------------------------------
#
# Version: 0.1 - 04/2009
#
# Usage: require "utils/fasta_utils"
#
# Fasta utilities
#
# 
#
#================================================

require File.dirname(__FILE__) +"/fasta_reader.rb"

	######################################
	# Define a subclass to override events
	######################################
class LoadFastaNamesInHash< FastaReader

	attr_reader :names

	#override begin processing
	def on_begin_process()
		@names = {}
	end

	def on_process_sequence(seq_name,seq_fasta)
		@names[seq_name]=true
	end

	#override end processing
	def on_end_process()
	end

end
