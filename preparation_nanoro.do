use residency_Nanoro_yacou_02052019,clear
rename IndividualId IndividualID 
sort IndividualID EventDate
gen socialgpid = substr(observeid,1,9)
gen locationid = substr(observeid,1,7)

bys IndividualID : replace socialgpid = socialgpid[_n-1] if socialgpid=="" & EventCode==9
rename Sex gender

keep IndividualID gender DoB EventCode EventDate socialgpid locationid
order IndividualID socialgpid locationid gender DoB EventDate  

gen hdss = "OU02"
save residency_Nanoro,replace