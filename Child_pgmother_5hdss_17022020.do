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
	
		
/****************CREATING Child dataset with pgmotherId ***************/
use  familly_final_5HDSS.dta, clear
drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "

*corrections à reverser dans la preparation des données
drop if pgmotherId=="unk"
drop if pgmotherId=="yama"
drop if pgmotherId=="---------"
duplicates drop hdss socialgpId IndividualId  pgmotherId,force
bys pgmotherId : gen nb_children = _N

ta nb_children

drop if nb_children>123
*56,118 observations deleted

*rename individualid IndividualId 
rename pgmotherId pgmotherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
*modif
keep IndividualId pgmotherid DoBPGM hdss socialgpId
*ds,has(type pgmotherid)
keep if pgmotherid!=" "
keep if pgmotherid!=""
*0 deleted

rename IndividualId ChildId
rename pgmotherid pgMotherId
sort pgMotherId ChildId
rename ChildId IndividualId
*modif
save pgmother_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import pgmotherId in the core residency file
*modif
merge m:1 hdss socialgpId IndividualId  using pgmother_childID_sahel.dta
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
save child_sahel_PGM, replace


/****************Create pgmother_children data*************/
use child_sahel_PGM, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook pgMotherId
**Uniqued pgMotherId =50,179
keep IndividualId pgMotherId DoB hdss socialgpId
duplicates drop IndividualId pgMotherId DoB hdss socialgpId,force
rename IndividualId ChildId
rename pgMotherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save pgmother_children_sahel, replace

***********Merge***Childpgmother data with pgmother Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1 hdss socialgpId IndividualId using pgmother_children_sahel.dta
*drop DoB*
rename _merge pgmotherdata
lab def pgmotherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val pgmotherdata pgmotherdata
codebook IndividualId if pgmotherdata!=1
*122,976
keep if pgmotherdata!=1
* 207,160 pgmothers 
tab pgmotherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if pgmotherdata==2 	
replace EventCode=9 if pgmotherdata==2



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident pgmothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence residencePGM
rename socialgpId  socialgpidPGM
rename DoB DoBPGM
bys IndividualId: replace DoBPGM = DoBPGM[_n-1] if missing(DoBPGM) & _n > 1 
bys IndividualId: replace DoBPGM = DoBPGM[_N]

count if DoBPGM==.


save pgmother_sahel, replace


/************Child with event history of the pgmother***********/

use pgmother_sahel, clear

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

rename EventCode EventCodePGM
rename EventDate EventDatePGM
rename IndividualId pgMotherId
*rename DoD DoDPGM
rename ChildId IndividualId
recode residencePGM .=0

 
order IndividualId child_rank pgMotherId EventDatePGM EventCodePGM 
sort IndividualId EventDatePGM EventCodePGM


count if EventDatePGM
bys IndividualId : replace last_record_date=21658  if EventDatePGM==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatePGM==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatePGM==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatePGM==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatePGM==. & hdss==5



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident pgmothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident pgmothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childPGM_sahel,replace


/***********************TMERGE*******************************/
capture erase child_pgmother_sahel.dta
clear
capture erase child_pgmother_sahel.dta
tmerge IndividualId child_sahel_PGM(EventDate) childPGM_sahel(EventDatePGM) ///
		child_pgmother_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodePGM = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_pgmother_sahel
count if pgmotherdata==2

count if socialgpidPGM ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

save child_pgmother_sahel,replace
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

save child_pgmother_sahel, replace


use child_pgmother_sahel,clear

*for socialgpidPGM
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodePGM=6 if EventCodePGM[_n-1] ==5 & EventCodePGM==9 & EventDate==EventDate[_n-1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodePGM=5 if EventCodePGM[_n-1] ==6 & EventCodePGM==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodePGM=6 if EventCodePGM[_n+1] ==5 & EventCodePGM==9 & EventDate==EventDate[_n+1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodePGM=5 if EventCodePGM[_n+1] ==6 & EventCodePGM==9 & EventDate==EventDate[_n+1]
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGM=socialgpidPGM[_n-2] if EventCodePGM==9 & EventCodePGM[_n-1]==9 
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGM=socialgpidPGM[_N] if EventCodePGM==9 & EventCodePGM[_N]==9 & _n==_N-1
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidPGM=socialgpId if EventCode==2
sort hdss IndividualId EventDate EventCode


sort hdss IndividualId EventDate 
capture drop dup_e
sort hdss IndividualId EventDate EventCode
 bys hdss IndividualId EventDate EventCode EventCodePGM socialgpidPGM: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpid=="" & socialgpidPGM==""
/*Indicateur de présence*/
capture drop coresidPGM
gen coresidPGM = (socialgpId==socialgpidPGM)

save child_pgmother_sahel_clean,replace

