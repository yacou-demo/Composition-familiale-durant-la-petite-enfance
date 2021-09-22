
*-------------------------------------------------------------------------------
                  **Child - Paternal uncles**
*-------------------------------------------------------------------------------

* Remove the existing folder (puncles)
shell rd "puncles" /s /q 

* Create it again in order to store the files maternal aunts file
mkdir puncles


forval i=1/20{
	
/****************CREATING Child dataset with FatherId ***************/
use  residency_final_5HDSS_res.dta,clear
*rename IndividualID IndividualId



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
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N


capture drop maxEventDate
bysort hdss  IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save residency_sahel.dta, replace

use  familly_final_5HDSS.dta, clear
*corrections à reverser dans la preparation des données
drop if puncleid_ego`i'=="unk"
drop if puncleid_ego`i'=="yama"
drop if puncleid_ego`i'=="---------"
duplicates drop hdss socialgpId IndividualId  puncleid_ego`i',force
bys puncleid_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename puncleid_ego`i' puncleid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId puncleid`i' DoB_puncle`i' hdss  socialgpId 
*ds,has(type fatherid)
keep if puncleid`i'!=" "
keep if puncleid`i'!=""
*0 deleted

rename IndividualId ChildId
rename puncleid`i' PuncleId`i'
sort PuncleId`i' ChildId
rename ChildId IndividualId
save puncle`i'_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import FatherId in the core residency file
merge m:1 hdss  socialgpId  IndividualId   using puncle`i'_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode

count if EventDate==.

bys hdss socialgpId  IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys hdss socialgpId  IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==2
bys hdss socialgpId  IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys hdss socialgpId  IndividualId  : replace last_record_date=20454  if EventDate==. & hdss==4
bys hdss socialgpId  IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==5


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_puncle`i', replace




/****************Create father_children data*************/
use child_sahel_puncle`i', clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook PuncleId`i'
**Uniqued FatherId =50,179
keep IndividualId PuncleId`i' DoB hdss socialgpId

duplicates drop
rename IndividualId ChildId
rename PuncleId`i' IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save puncle`i'_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId

merge m:1  hdss  socialgpId  IndividualId  using puncle`i'_children_sahel.dta
*drop DoB*

rename _merge puncle`i'data
lab def puncle`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val puncle`i'data puncle`i'data
codebook IndividualId if puncle`i'data!=1
*122,976
keep if puncle`i'data!=1
* 207,160 fathers 
tab puncle`i'data
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if puncle`i'data==2 	
replace EventCode=9 if puncle`i'data==2


* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*drop if maxEventDate==.
drop maxEventDate 
rename residence res_puncle`i'
rename socialgpId  sgp_puncle`i'
rename DoB DoB_puncle`i'
bys IndividualId: replace DoB_puncle`i' = DoB_puncle`i'[_n-1] if missing(DoB_puncle`i') & _n > 1 
bys IndividualId: replace DoB_puncle`i' = DoB_puncle`i'[_N]

count if DoB_puncle`i'==.

save puncle`i'_sahel, replace


/************Child with event history of the father***********/

use puncle`i'_sahel, clear

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

rename EventCode EventCodepuncle`i'
rename EventDate EventDatepuncle`i'
rename IndividualId PuncleId`i'
*rename DoD DoDFA
rename ChildId IndividualId
recode res_puncle`i' .=0

 
order IndividualId child_rank PuncleId`i' EventDatepuncle`i' EventCodepuncle`i' 
sort IndividualId EventDatepuncle`i' EventCodepuncle`i' 


count if EventDatepuncle`i'==.

bys IndividualId : replace last_record_date=21658  if EventDatepuncle`i'==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatepuncle`i'==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatepuncle`i'==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatepuncle`i'==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatepuncle`i'==. & hdss==5



* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss  IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childpuncle`i'_sahel,replace

/***********************TMERGE*******************************/
capture erase child_puncle`i'_sahel.dta
clear
capture erase child_puncle`i'_sahel.dta
tmerge IndividualId child_sahel_puncle`i'(EventDate) childpuncle`i'_sahel(EventDatepuncle`i') ///
		child_puncle`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodepuncle`i'  = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_puncle`i'_sahel
count if puncle`i'data==2

count if sgp_puncle`i' ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss socialgpId IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

count if socialgpId=="" & sgp_puncle`i'==""
/*Indicateur de présence*/
gen coresidpuncle`i' = (socialgpId==sgp_puncle`i')

cd puncles
*123157 naissances
save child_puncle_`i', replace
cd ..
}

