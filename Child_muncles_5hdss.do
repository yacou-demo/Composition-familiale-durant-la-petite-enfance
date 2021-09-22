
*-------------------------------------------------------------------------------
                  **Child - Maternal uncles**
*-------------------------------------------------------------------------------

* Remove the existing folder (muncles)
shell rd "muncles" /s /q 

* Create it again in order to store the files maternal uncles file
mkdir muncles

forval i=1/20{
	
/****************CREATING Child dataset with FatherId ***************/
use  residency_final_5HDSS_res.dta,clear
*rename IndividualID IndividualId
drop if socialgpid=="."
drop if socialgpid==""
drop if socialgpid==" "

*Add half day to Entry date
replace EventDate = EventDate if EventCode==6



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
bysort hdss  IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save residency_sahel.dta, replace

use  familly_final_5HDSS.dta, clear
drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "
*corrections à reverser dans la preparation des données
drop if muncleid_ego`i'=="unk"
drop if muncleid_ego`i'=="yama"
drop if muncleid_ego`i'=="---------"
duplicates drop hdss socialgpId IndividualId  muncleid_ego1,force
bys muncleid_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename muncleid_ego`i' muncleid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId muncleid`i' DoB_muncle`i' hdss  socialgpId 
*ds,has(type fatherid)
keep if muncleid`i'!=" "
keep if muncleid`i'!=""
*0 deleted

rename IndividualId ChildId
rename muncleid`i' MuncleId`i'
sort MuncleId`i' ChildId
rename ChildId IndividualId
save muncle`i'_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import FatherId in the core residency file
merge m:1 hdss  socialgpId  IndividualId   using muncle`i'_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode

count if EventDate==.

bys hdss socialgpId  IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys hdss socialgpId  IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==2
bys hdss socialgpId  IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys hdss socialgpId  IndividualId  : replace last_record_date=20454  if EventDate==. & hdss==4
bys hdss socialgpId  IndividualId  : replace last_record_date=21185  if EventDate==. & hdss==5


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
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N

capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_muncle`i', replace




/****************Create father_children data*************/
use child_sahel_muncle`i', clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook MuncleId`i'
**Uniqued FatherId =50,179
keep IndividualId MuncleId`i' DoB hdss socialgpId

duplicates drop IndividualId MuncleId`i' DoB hdss socialgpId,force
rename IndividualId ChildId
rename MuncleId`i' IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save muncle`i'_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId

merge m:1  hdss  socialgpId  IndividualId  using muncle`i'_children_sahel.dta
*drop DoB*

rename _merge muncle`i'data
lab def muncle`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val muncle`i'data muncle`i'data
codebook IndividualId if muncle`i'data!=1
*122,976
keep if muncle`i'data!=1
* 207,160 fathers 
tab muncle`i'data
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if muncle`i'data==2 	
replace EventCode=9 if muncle`i'data==2



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
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence res_muncle`i'
rename socialgpId  sgp_muncle`i'
rename DoB DoB_muncle`i'
bys IndividualId: replace DoB_muncle`i' = DoB_muncle`i'[_n-1] if missing(DoB_muncle`i') & _n > 1 
bys IndividualId: replace DoB_muncle`i' = DoB_muncle`i'[_N]

count if DoB_muncle`i'==.

save muncle`i'_sahel, replace


/************Child with event history of the father***********/

use muncle`i'_sahel, clear

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

rename EventCode EventCodemuncle`i'
rename EventDate EventDatemuncle`i'
rename IndividualId MuncleId`i'
*rename DoD DoDFA
rename ChildId IndividualId
recode res_muncle`i' .=0

 
order IndividualId child_rank MuncleId`i' EventDatemuncle`i' EventCodemuncle`i' 
sort IndividualId EventDatemuncle`i' EventCodemuncle`i' 


count if EventDatemuncle`i'==.

bys IndividualId : replace last_record_date=21658  if EventDatemuncle`i'==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatemuncle`i'==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatemuncle`i'==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatemuncle`i'==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatemuncle`i'==. & hdss==5



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
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childmuncle`i'_sahel,replace

/***********************TMERGE*******************************/
capture erase child_muncle`i'_sahel.dta
clear
capture erase child_muncle`i'_sahel.dta
tmerge IndividualId child_sahel_muncle`i'(EventDate) childmuncle`i'_sahel(EventDatemuncle`i') ///
		child_muncle`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodemuncle`i'  = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_muncle`i'_sahel
count if muncle`i'data==2

count if sgp_muncle`i' ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss socialgpId IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

count if socialgpId=="" & sgp_muncle`i'==""
/*Indicateur de présence*/
gen coresidmuncle`i' = (socialgpId==sgp_muncle`i')

cd muncles
*123157 naissances
save child_muncle_`i', replace
cd ..
}






