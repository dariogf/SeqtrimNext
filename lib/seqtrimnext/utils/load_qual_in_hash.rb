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

require File.dirname(__FILE__) +"/qual_reader.rb"

	######################################
	# Define a subclass to override events
	######################################
class LoadQualInHash< QualReader

	attr_reader :quals

	#override begin processing
	def on_begin_process()
		@quals = {}
	end

	def on_process_sequence(seq_name,seq_qual)
		@quals[seq_name]=seq_qual
	end

	#override end processing
	def on_end_process()
	end

end
