use  residency_final_5HDSS_res.dta,clear
*modify
drop if socialgpid=="."
drop if socialgpid==""
drop if socialgpid==" "
egen concat_IndividualId = concat(hdss IndividualId)
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 by concat_IndividualId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1



*Create an extra line for pregnant event (DoB - 6 months)
sort IndividualId EventDate

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
7 "DTH" 8"-6mDTH" 9 "OBE" 10 "DLV" 11"PREGNANT"18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab

ta EventCode,m

*Modification 30012019
*drop if EventCode==30
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort hdss IndividualId EventDate EventCode
bys hdss IndividualId : replace EventCode=9 if _n==_N


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save residency_sahel.dta, replace
	
		
/****************CREATING Child dataset with pgFatherId ***************/
use  familly_final_5HDSS.dta, clear
drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "

*corrections à reverser dans la preparation des données
drop if pgfatherId=="unk"
drop if pgfatherId=="yama"
drop if pgfatherId=="---------"
duplicates drop hdss socialgpId IndividualId  pgfatherId,force
bys pgfatherId : gen nb_children = _N

ta nb_children

drop if nb_children>161
*56,118 observations deleted

*rename individualid IndividualId 
rename pgfatherId pgfatherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
*modif
keep IndividualId pgfatherid DoBPGF hdss socialgpId
*ds,has(type pgfatherid)
keep if pgfatherid!=" "
keep if pgfatherid!=""
*0 deleted

rename IndividualId ChildId
rename pgfatherid pgFatherId
sort pgFatherId ChildId
rename ChildId IndividualId
*modif
save pgfather_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import pgfatherId in the core residency file
*modif
merge m:1 hdss socialgpId IndividualId  using pgfather_childID_sahel.dta
keep if _merge==3
keep if _merge==3
sort hdss IndividualId EventDate EventCode

count if EventDate==.

bys    IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys    IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==2
bys    IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys    IndividualId  : replace last_record_date=20454  if EventDate==. & hdss==4
bys    IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==5
count if EventDate==.

*modif
replace EventDate = last_record_date if EventDate==.

capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

*modif
* Need recoding for these individuals
sort hdss  IndividualId EventDate EventCode
bys hdss  IndividualId : replace EventCode=9 if _n==_N

*modif 
drop if EventCode==.
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_PGF, replace


/****************Create pgfather_children data*************/
use child_sahel_PGF, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook pgFatherId
**Uniqued pgFatherId =50,179
keep IndividualId pgFatherId DoB hdss socialgpId
duplicates drop IndividualId pgFatherId DoB hdss socialgpId,force
rename IndividualId ChildId
rename pgFatherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save pgfather_children_sahel, replace

***********Merge***Childpgfather data with pgfather Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1 hdss socialgpId IndividualId using pgfather_children_sahel.dta
*drop DoB*
rename _merge pgfatherdata
lab def pgfatherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val pgfatherdata pgfatherdata
codebook IndividualId if pgfatherdata!=1
*122,976
keep if pgfatherdata!=1
* 207,160 pgfathers 
tab pgfatherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if pgfatherdata==2 	
replace EventCode=9 if pgfatherdata==2



capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort hdss IndividualId EventDate EventCode
bys hdss IndividualId : replace EventCode=9 if _n==_N




* to check that all EventDate end up 1 Jan 2013 except for non-resident pgfathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence residencePGF
rename socialgpId  socialgpidPGF
rename DoB DoBPGF
bys IndividualId: replace DoBPGF = DoBPGF[_n-1] if missing(DoBPGF) & _n > 1 
bys IndividualId: replace DoBPGF = DoBPGF[_N]

count if DoBPGF==.


save pgfather_sahel, replace


/************Child with event history of the pgfather***********/

use pgfather_sahel, clear

bysort IndividualId (EventDate): gen IndividualId_ep = IndividualId+string(EventDate) + string(_n) + string(hdss)
*bysort IndividualId (EventDate): gen a = _n 
reshape long ChildId, i(IndividualId_ep) j(child_rank)

order IndividualId_ep ChildId 
replace gender=2 if gender==1 /*added*/
*18,960 
*drop gender
drop if ChildId == ""
drop if ChildId == " "

drop IndividualId_ep
codebook ChildId
*3,944,319(unique ChildId 246,543)

rename EventCode EventCodePGF
rename EventDate EventDatePGF
rename IndividualId pgFatherId
*rename DoD DoDPGF
rename ChildId IndividualId
recode residencePGF .=0

 
order IndividualId child_rank pgFatherId EventDatePGF EventCodePGF 
sort IndividualId EventDatePGF EventCodePGF


count if EventDatePGF
bys IndividualId : replace last_record_date=21658  if EventDatePGF==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatePGF==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatePGF==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatePGF==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatePGF==. & hdss==5



capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort hdss IndividualId EventDate EventCode
bys hdss IndividualId : replace EventCode=9 if _n==_N




* to check that all EventDate end up 1 Jan 2013 except for non-resident pgfathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident pgfathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childPGF_sahel,replace


/***********************TMERGE*******************************/
capture erase child_pgfather_sahel.dta
clear
capture erase child_pgfather_sahel.dta
tmerge IndividualId child_sahel_PGF(EventDate) childPGF_sahel(EventDatePGF) ///
		child_pgfather_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodePGF = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_pgfather_sahel
count if pgfatherdata==2

count if socialgpidPGF ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

save child_pgfather_sahel,replace
*Corrections
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCode=6 if EventCode[_n-1] ==5 & EventCode==9 & EventDate==EventDate[_n-1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCode=5 if EventCode[_n-1] ==6 & EventCode==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCode=6 if EventCode[_n+1] ==5 & EventCode==9 & EventDate==EventDate[_n+1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCode=5 if EventCode[_n+1] ==6 & EventCode==9 & EventDate==EventDate[_n+1]
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace socialgpId=socialgpId[_n-1] if _n==2 & socialgpId!=socialgpId[_n-1]
sort hdss IndividualId EventDate EventCode

save child_pgfather_sahel, replace


use child_pgfather_sahel,clear

*for socialgpidPGF
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodePGF=6 if EventCodePGF[_n-1] ==5 & EventCodePGF==9 & EventDate==EventDate[_n-1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodePGF=5 if EventCodePGF[_n-1] ==6 & EventCodePGF==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodePGF=6 if EventCodePGF[_n+1] ==5 & EventCodePGF==9 & EventDate==EventDate[_n+1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodePGF=5 if EventCodePGF[_n+1] ==6 & EventCodePGF==9 & EventDate==EventDate[_n+1]
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGF=socialgpidPGF[_n-2] if EventCodePGF==9 & EventCodePGF[_n-1]==9 
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGF=socialgpidPGF[_N] if EventCodePGF==9 & EventCodePGF[_N]==9 & _n==_N-1
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGF=socialgpId if EventCode==2
sort hdss IndividualId EventDate EventCode


sort hdss IndividualId EventDate 
capture drop dup_e
sort hdss IndividualId EventDate EventCode
 bys hdss IndividualId EventDate EventCode EventCodePGF socialgpidPGF: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpid=="" & socialgpidPGF==""
/*Indicateur de présence*/
capture drop coresidPGF
gen coresidPGF = (socialgpId==socialgpidPGF)

save child_pgfather_sahel_clean,replace

