*******************************************************************************
* _api_read_indicators                                                                     *
*! v 15.2   10Mar2019				by João Pedro Azevedo
*		rename ado : _wbopendata_update.ado  to _update_indicators.ado
/*******************************************************************************

cd "C:\GitHub_myados\wbopendata\src"

! git checkout dev

discard

_api_read_indicators, update preserveout


*******************************************************************************/

program define _api_read_indicators, rclass

	*====================================================================================

	version 9
	
    syntax                                         ///
                 ,                                 ///
                         UPDATE		               ///
						 [ PRESERVEOUT ]			   
                 

	
	quietly {
	
		set checksum off

		************************************
		/* Overall Parameters			  */
		************************************

		local date: disp %td date("`c(current_date)'", "DMY")
	
		tempfile indicator1 indicator2

		local query1 "http://api.worldbank.org/v2/indicators?per_page=10000&page=1"
		local query2 "http://api.worldbank.org/v2/indicators?per_page=10000&page=2"

		****************************************
		/* Download Indicator list using API  */
		****************************************

		noi di in smcl in g ""
		noi di in smcl in g "{bf: Downloading indicators list 1/2...}"

		cap: copy "`query1'" "`indicator1'", text replace	
		
		noi di in smcl in g ""
		noi di in smcl in g "{bf: Downloading indicators list 1/2...COMPLETED!}"
		
		noi di in smcl in g ""
		noi di in smcl in g "{bf: Downloading indicators list 2/2...}"
		
		cap: copy "`query2'" "`indicator2'", text replace

		noi di in smcl in g ""
		noi di in smcl in g "{bf: Downloading indicators list 2/2...COMPLETED!}"

		noi di in smcl in g ""
		noi di in smcl in g "{bf: Executing update...}"

		
		************************************
		/* Preapre Indicator list (TXT)	  */
		************************************
	
		tempfile in out source out3 hlp1 hlp2 indicator help file1 file2
		tempname in2 in3 out2 in_tmp saving source1 source2 source3 source4 hlp hlp01 hlp02
			   
		local skipnumber = 1
		local trimnumber = 1
	   
		file open `in2'     using 	`indicator1'		, read
		file open `in3'     using 	`indicator2'   		, read 

		if ("`preserveout'" == "") {
			file open `out2'    using 	`out'     		, write text replace
			file open `source3' using 	`file1'  		, write text replace
			file open `source4' using 	`file2'  		, write text replace
		}
		else {
			file open `out2'    using 	out.txt    		, write text replace
			file open `source3' using 	file1.txt  		, write text replace
			file open `source4' using 	file2.txt  		, write text replace
		}
		
		file open `source2' using 	`indicator'  		, write text replace
		file open `hlp01'	using 	`hlp1'				, write text replace
		
		file write `source3' "indicatorcode#type#valuelabel# " _n
		
		file write `source4' "indicatorcode#indicatorname#sourceID #sourceOrganization #sourceNote #type # topicID " _n

		foreach inputfile in in2 in3 {
		
			file read ``inputfile'' line
			local l = 0
				 while !r(eof) {
					  local ++l
					  file read ``inputfile'' line
					  if(`l'>`skipnumber') {
						local line = subinstr(`"`line'"', `"""', "", .)
						file write `out2' `"`line'"' _n
						if ("`line'" != "") {
							local line = subinstr(`"`line'"', `"""', "", .)
							
							if (strmatch("`line'", "*<wb:indicator id=*")==1) {
								local namevar = "`line'"
								local namevar = trim(subinstr("`namevar'","<wb:indicator id=","",.))
								local namevar = subinstr("`namevar'",">"," - ",.)
								local namevar2 = subinstr("`namevar'"," - ","",.)
								file write `source2' "`namevar'" 
								*file write `source3' "`namevar2' # # # " _n
							}
							
							if (strmatch("`line'", "*<wb:name>*")==1) {
								local labvar = "`line'"
								local labvar = trim(subinstr("`labvar'","<wb:name>","",.))
								local labvar = subinstr("`labvar'","</wb:name>","",.)
								local labvar = trim(substr("`labvar'",1,200))
								file write `source2' "`labvar'" _n
								file write `hlp01' "{synopt:{opt `namevar2'}} `labvar'{p_end}" 	_n
								file write `source3' "`namevar2' # indicatorname # `labvar' # " _n
							}
						
							if (strmatch("`line'", "*<wb:source id=*")==1) {
								local sourceID = "`line'"
								local sourceID = trim(subinstr("`sourceID'","<wb:source id=","",.))
								local sourceID = subinstr("`sourceID'","</wb:source>","",.)
								file write `source3' "`namevar2' # sourceID # `sourceID' # " _n
							}
							
							if (strmatch("`line'", "*<wb:sourceNote>*")==1) {
								local sourceNote = "`line'"
								local sourceNote = trim(subinstr("`sourceNote'","<wb:sourceNote>","",.))
								local sourceNote = subinstr("`sourceNote'","</wb:sourceNote>","",.)
								file write `source3' "`namevar2' # sourceNote # `sourceNote' #"  _n
							}
						
							if (strmatch("`line'", "*<wb:sourceOrganization>*")==1) {
								local sourceOrganization = "`line'"
								local sourceOrganization = trim(subinstr("`sourceOrganization'","<wb:sourceOrganization>","",.))
								local sourceOrganization = subinstr("`sourceOrganization'","</wb:sourceOrganization>","",.)
								file write `source3' "`namevar2' # sourceOrganization # `sourceOrganization' #"  _n
							}
							
							if (strmatch("`line'", "*<wb:topic id=*")==1) {
								local topicID = "`line'"
								local topicID = trim(subinstr("`topicID'","<wb:topic id=","",.))
								local topicID = subinstr("`topicID'","</wb:topic>","",.)
								file write `source3' "`namevar2' # topicID # `topicID'" _n
								file write `source4' "`namevar2' # `labvar' # `sourceID' # `sourceOrganization' # `sourceNote' # topicID # `topicID'" _n
							}							
							
							if (strmatch("`line'", "*<wb:topic id=*")!=1) {
								file write `source4' "`namevar2' # `labvar' # `sourceID' # `sourceOrganization' # `sourceNote' # topicID #   " _n
							}
						}
					  }
				}
		}


		
		file close `in2'
		file close `in3'
		file close `out2'
		
		file close `source2'
		file close `source3'
		file close `source4'

		file close `hlp01'
		
		************************************
		/* Final files			  */
		************************************

		
		************************************
		/* Final files			  */
		************************************

		
	noi di in smcl in g ""
	noi di in smcl in g "{bf: Update...COMPLETED!}"
	noi di in smcl in g ""

	
	*====================================================================================

	}

end


*******************************************************************************
* v 14.3  	2Feb2019               	by Joao Pedro Azevedo                     