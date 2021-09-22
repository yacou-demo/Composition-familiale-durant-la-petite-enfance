*-------------------------------------------------------------------------------
                  **Child - Paternal aunts**
*-------------------------------------------------------------------------------

* Remove the existing folder (paunts)
shell rd "paunts" /s /q 

* Create it again in order to store the files maternal aunts file
mkdir paunts

forval i=1/18{
	
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
drop if paunt_ego`i'=="unk"
drop if paunt_ego`i'=="yama"
drop if paunt_ego`i'=="---------"
duplicates drop hdss  socialgpId IndividualId  paunt_ego`i',force
bys paunt_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename paunt_ego`i' pauntid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId pauntid`i' DoB_paunt`i' hdss  socialgpId 
*ds,has(type fatherid)
keep if pauntid`i'!=" "
keep if pauntid`i'!=""
*0 deleted

rename IndividualId ChildId
rename pauntid`i' PauntId`i'
sort PauntId`i' ChildId
rename ChildId IndividualId
save paunt`i'_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import FatherId in the core residency file
merge m:1 hdss    IndividualId   using paunt`i'_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode

count if EventDate==.

bys hdss   IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys hdss   IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==2
bys hdss   IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys hdss   IndividualId  : replace last_record_date=20454  if EventDate==. & hdss==4
bys hdss   IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==5


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_paunt`i', replace




/****************Create father_children data*************/
use child_sahel_paunt`i', clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook PauntId`i'
**Uniqued FatherId =50,179
keep IndividualId PauntId`i' DoB hdss socialgpId

duplicates drop
rename IndividualId ChildId
rename PauntId`i' IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save paunt`i'_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId

merge m:1  hdss  socialgpId  IndividualId  using paunt`i'_children_sahel.dta
*drop DoB*

rename _merge paunt`i'data
lab def paunt`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val paunt`i'data paunt`i'data
codebook IndividualId if paunt`i'data!=1
*122,976
keep if paunt`i'data!=1
* 207,160 fathers 
tab paunt`i'data
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if paunt`i'data==2 	
replace EventCode=9 if paunt`i'data==2


* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*drop if maxEventDate==.
drop maxEventDate 
rename residence res_paunt`i'
rename socialgpId  sgp_paunt`i'
rename DoB DoB_paunt`i'
bys IndividualId: replace DoB_paunt`i' = DoB_paunt`i'[_n-1] if missing(DoB_paunt`i') & _n > 1 
bys IndividualId: replace DoB_paunt`i' = DoB_paunt`i'[_N]

count if DoB_paunt`i'==.

save paunt`i'_sahel, replace


/************Child with event history of the father***********/

use paunt`i'_sahel, clear

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

rename EventCode EventCodepaunt`i'
rename EventDate EventDatepaunt`i'
rename IndividualId PauntId`i'
*rename DoD DoDFA
rename ChildId IndividualId
recode res_paunt`i' .=0

 
order IndividualId child_rank PauntId`i' EventDatepaunt`i' EventCodepaunt`i' 
sort IndividualId EventDatepaunt`i' EventCodepaunt`i' 


count if EventDatepaunt`i'==.

bys IndividualId : replace last_record_date=21658  if EventDatepaunt`i'==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatepaunt`i'==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatepaunt`i'==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatepaunt`i'==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatepaunt`i'==. & hdss==5



* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss  IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childpaunt`i'_sahel,replace

/***********************TMERGE*******************************/
capture erase child_paunt`i'_sahel.dta
clear
capture erase child_paunt`i'_sahel.dta
tmerge IndividualId child_sahel_paunt`i'(EventDate) childpaunt`i'_sahel(EventDatepaunt`i') ///
		child_paunt`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodepaunt`i'  = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_paunt`i'_sahel
count if paunt`i'data==2

count if sgp_paunt`i' ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss socialgpId IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

count if socialgpId=="" & sgp_paunt`i'==""
/*Indicateur de présence*/
gen coresidpaunt`i' = (socialgpId==sgp_paunt`i')

cd paunts
*123157 naissances
save child_paunt_`i', replace
cd ..
}
