use  Residency_Final.dta,clear

rename individid IndividualID 
sort IndividualID EventDate
gen socialgpid = substr(observeid,1,16)
bys IndividualID : replace socialgpid = socialgpid[_n-1] if socialgpid=="" & EventCode==9

keep IndividualID gender DoB EventCode EventDate socialgpid locationid
order IndividualID socialgpid locationid gender DoB EventDate  

gen hdss = "OU01"
save residency_Ouaga,replace