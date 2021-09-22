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
	
		
/****************CREATING Child dataset with FatherId ***************/
use  familly_final_5HDSS.dta, clear
drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "

*corrections à reverser dans la preparation des données
drop if fatherId=="unk"
drop if fatherId=="yama"
drop if fatherId=="---------"
duplicates drop hdss socialgpId IndividualId  fatherId,force
bys fatherId : gen nb_children = _N

ta nb_children

drop if nb_children>84
*56,118 observations deleted

*rename individualid IndividualId 
rename fatherId fatherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
*modif
keep IndividualId fatherid DoBFA hdss socialgpId
*ds,has(type fatherid)
keep if fatherid!=" "
keep if fatherid!=""
*0 deleted

rename IndividualId ChildId
rename fatherid FatherId
sort FatherId ChildId
rename ChildId IndividualId
*modif
save father_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import FatherId in the core residency file
*modif
merge m:1 hdss socialgpId IndividualId  using father_childID_sahel.dta
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
save child_sahel_FA, replace


/****************Create father_children data*************/
use child_sahel_FA, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook FatherId
**Uniqued FatherId =50,179
keep IndividualId FatherId DoB hdss socialgpId
duplicates drop IndividualId FatherId DoB hdss socialgpId,force
rename IndividualId ChildId
rename FatherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save father_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1 hdss socialgpId IndividualId using father_children_sahel.dta
*drop DoB*
rename _merge fatherdata
lab def fatherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val fatherdata fatherdata
codebook IndividualId if fatherdata!=1
*122,976
keep if fatherdata!=1
* 207,160 fathers 
tab fatherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if fatherdata==2 	
replace EventCode=9 if fatherdata==2



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence residenceFA
rename socialgpId  socialgpidFA
rename DoB DoBFA
bys IndividualId: replace DoBFA = DoBFA[_n-1] if missing(DoBFA) & _n > 1 
bys IndividualId: replace DoBFA = DoBFA[_N]

count if DoBFA==.


save father_sahel, replace


/************Child with event history of the father***********/

use father_sahel, clear

bysort IndividualId (EventDate): gen IndividualId_ep = IndividualId+string(EventDate) + string(_n) + string(hdss)
*bysort IndividualId (EventDate): gen a = _n 
reshape long ChildId, i(IndividualId_ep) j(child_rank)

order IndividualId_ep ChildId 
replace gender=1 if gender==2 /*added*/
*18,960 
*drop gender
drop if ChildId == ""
drop if ChildId == " "

drop IndividualId_ep
codebook ChildId
*3,944,319(unique ChildId 246,543)

rename EventCode EventCodeFA
rename EventDate EventDateFA
rename IndividualId FatherId
*rename DoD DoDFA
rename ChildId IndividualId
recode residenceFA .=0

 
order IndividualId child_rank FatherId EventDateFA EventCodeFA 
sort IndividualId EventDateFA EventCodeFA


count if EventDateFA
bys IndividualId : replace last_record_date=21658  if EventDateFA==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDateFA==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDateFA==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDateFA==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDateFA==. & hdss==5



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childFA_sahel,replace


/***********************TMERGE*******************************/
capture erase child_father_sahel.dta
clear
capture erase child_father_sahel.dta
tmerge IndividualId child_sahel_FA(EventDate) childFA_sahel(EventDateFA) ///
		child_father_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodeFA = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_father_sahel
count if fatherdata==2

count if socialgpidFA ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0


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

save child_father_sahel, replace


use child_father_sahel,clear

*for socialgpidFA
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodeFA=6 if EventCodeFA[_n-1] ==5 & EventCodeFA==9 & EventDate==EventDate[_n-1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodeFA=5 if EventCodeFA[_n-1] ==6 & EventCodeFA==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventCodeFA=6 if EventCodeFA[_n+1] ==5 & EventCodeFA==9 & EventDate==EventDate[_n+1]

sort hdss IndividualId EventDate
bys hdss  IndividualId : replace EventCodeFA=5 if EventCodeFA[_n+1] ==6 & EventCodeFA==9 & EventDate==EventDate[_n+1]
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidFA=socialgpidFA[_n-2] if EventCodeFA==9 & EventCodeFA[_n-1]==9 
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace socialgpidFA=socialgpidFA[_N] if EventCodeFA==9 & EventCodeFA[_N]==9 & _n==_N-1
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
capture drop dup_e
sort hdss IndividualId EventDate EventCode
 bys hdss IndividualId EventDate EventCode EventCodeFA socialgpidFA: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpid=="" & socialgpidFA==""
/*Indicateur de présence*/
capture drop coresidFA
gen coresidFA = (socialgpId==socialgpidFA)

save child_father_sahel_clean,replace

