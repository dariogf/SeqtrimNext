
class Hash

#increments a hash with the stats defined in h_stats

# three levels:
# STATS->plugin_name->Property->count

def add_stats(h_stats)
	h=self

	h_stats.each do |plugin_hash,add_stats|
		h[plugin_hash]={} if h[plugin_hash].nil?	
		
		add_stats.each do |property,hash_value|
			h[plugin_hash][property]={} if h[plugin_hash][property].nil?	
		
      # values need to be in string format because of later loading from json file
			hash_value.each do |value, count|
				h[plugin_hash][property][value.to_s]=(h[plugin_hash][property][value.to_s]||0) + count
			end
		end
	end

end            
                


end

