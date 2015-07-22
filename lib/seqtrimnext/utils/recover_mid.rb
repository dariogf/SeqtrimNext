module RecoverMid

  #receives hit of mid from blast, complete db_mid from DB and SEQ_fasta
  def recover_mid(hit, db_mid, seq)
  
    mid_in_seq = seq[hit.q_beg..hit.q_end]  
    mid_in_mid = db_mid[hit.s_beg..hit.s_end]

		if hit.s_beg==0 # look right parts
	
			mid_part=db_mid[hit.s_end+1..db_mid.length]
	 	  seq_part=seq[hit.q_end+1,mid_part.length+1]
	 	  
	 	  common=mid_part.lcs(seq_part)
	 	  
	 	  
	 	  in_seq_pos=seq_part.index(common)
			  
        # puts "seq right part: #{seq_part}, mid right part #{mid_part} => Match: #{common}"
		
	 	  if in_seq_pos>1 #

          # puts "NO VALE, comienza en #{in_seq_pos}"
	 	    in_seq_pos=0
		 	  	common=''
		 	end

			new_q_beg=hit.q_beg
			new_q_end=hit.q_end+in_seq_pos+common.length
			recovered_mid=seq[new_q_beg..new_q_end]

			recovered_size=hit.q_end-hit.q_beg+1+common.length

		
		else hit.s_end == db_mid.length-1#look left parts
			mid_part=db_mid[0..hit.s_beg-1]
	 	  seq_part=seq[hit.q_beg-mid_part.length-1..hit.q_beg-1]
	 	  
	 	  common=mid_part.lcs(seq_part)
	 	  
	 	  in_seq_pos=hit.q_beg-mid_part.length-1+seq_part.index(common)
			  
        # puts "seq left part: #{seq_part}, mid right part #{mid_part} => Match: #{common} at #{in_seq_pos}"
		
	 	  if in_seq_pos+common.length<hit.q_beg-1 
          # puts "NO VALE, comienza en #{in_seq_pos+common.length} < #{hit.q_beg}"
	 	    in_seq_pos=hit.q_beg
		 	  	common=''
		 	end

			new_q_beg=in_seq_pos
			new_q_end=hit.q_end
			recovered_mid=seq[new_q_beg..new_q_end]

			recovered_size=hit.q_end-hit.q_beg+1+common.length
	
		end
		
		return [new_q_beg, new_q_end, recovered_size,recovered_mid]
	
	end

end

class String
		def lcs(s2)
			s1=self
			res="" 
			num=Array.new(s1.size){Array.new(s2.size)}
			len,ans=0
			lastsub=0
			s1.scan(/./).each_with_index do |l1,i |
				s2.scan(/./).each_with_index do |l2,j |
				  unless l1==l2
				    num[i][j]=0
				  else
				    (i==0 || j==0)? num[i][j]=1 : num[i][j]=1 + num[i-1][j-1]
				    if num[i][j] > len
				      len = ans = num[i][j]
				      thissub = i
				      thissub -= num[i-1][j-1] unless num[i-1][j-1].nil?  
				      if lastsub==thissub
				        res+=s1[i,1]
				      else
				        lastsub=thissub
				        res=s1[lastsub, (i+1)-lastsub]
				      end
				    end
				  end
				end
			end
			res
		end
end

