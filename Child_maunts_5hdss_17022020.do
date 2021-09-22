*-------------------------------------------------------------------------------
                  **Child - Paternal aunts**
*-------------------------------------------------------------------------------

* Remove the existing folder (maunts)
shell rd "maunts"  /s /q 

* Create it again in order to store the files maternal aunts file
mkdir maunts

forval i=1/18{
	
/****************CREATING Child dataset with FatherId ***************/
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

use  familly_final_5HDSS.dta, clear
drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "
*corrections à reverser dans la preparation des données
drop if maunt_ego`i'=="unk"
drop if maunt_ego`i'=="yama"
drop if maunt_ego`i'=="---------"
duplicates drop hdss socialgpId IndividualId  maunt_ego`i',force
bys maunt_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename maunt_ego`i' mauntid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId mauntid`i' DoB_maunt`i' hdss  socialgpId 
*ds,has(type fatherid)
keep if mauntid`i'!=" "
keep if mauntid`i'!=""
*0 deleted

rename IndividualId ChildId
rename mauntid`i' MauntId`i'
sort MauntId`i' ChildId
rename ChildId IndividualId
save maunt`i'_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import FatherId in the core residency file
merge m:1 hdss  socialgpId  IndividualId   using maunt`i'_childID_sahel.dta
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
sort hdss IndividualId EventDate EventCode
bys hdss IndividualId : replace EventCode=9 if _n==_N

capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_maunt`i', replace




/****************Create father_children data*************/
use child_sahel_maunt`i', clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook MauntId`i'
**Uniqued FatherId =50,179
keep IndividualId MauntId`i' DoB hdss socialgpId

duplicates drop IndividualId MauntId`i' DoB hdss socialgpId,force
rename IndividualId ChildId
rename MauntId`i' IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(socialgpId IndividualId hdss) j(child_rank)

save maunt`i'_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId

merge m:1  hdss  socialgpId  IndividualId  using maunt`i'_children_sahel.dta
*drop DoB*

rename _merge maunt`i'data
lab def maunt`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val maunt`i'data maunt`i'data
codebook IndividualId if maunt`i'data!=1
*122,976
keep if maunt`i'data!=1
* 207,160 fathers 
tab maunt`i'data
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5


replace EventDate=last_record_date if maunt`i'data==2 	
replace EventCode=9 if maunt`i'data==2



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
rename residence res_maunt`i'
rename socialgpId  sgp_maunt`i'
rename DoB DoB_maunt`i'
bys IndividualId: replace DoB_maunt`i' = DoB_maunt`i'[_n-1] if missing(DoB_maunt`i') & _n > 1 
bys IndividualId: replace DoB_maunt`i' = DoB_maunt`i'[_N]

count if DoB_maunt`i'==.

save maunt`i'_sahel, replace


/************Child with event history of the father***********/

use maunt`i'_sahel, clear

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

rename EventCode EventCodemaunt`i'
rename EventDate EventDatemaunt`i'
rename IndividualId MauntId`i'
*rename DoD DoDFA
rename ChildId IndividualId
recode res_maunt`i' .=0

 
order IndividualId child_rank MauntId`i' EventDatemaunt`i' EventCodemaunt`i' 
sort IndividualId EventDatemaunt`i' EventCodemaunt`i' 


count if EventDatemaunt`i'==.

bys IndividualId : replace last_record_date=21658  if EventDatemaunt`i'==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDatemaunt`i'==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDatemaunt`i'==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDatemaunt`i'==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDatemaunt`i'==. & hdss==5



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

save childmaunt`i'_sahel,replace

/***********************TMERGE*******************************/
capture erase child_maunt`i'_sahel.dta
clear
capture erase child_maunt`i'_sahel.dta
tmerge IndividualId child_sahel_maunt`i'(EventDate) childmaunt`i'_sahel(EventDatemaunt`i') ///
		child_maunt`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodemaunt`i'  = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_maunt`i'_sahel
count if maunt`i'data==2

count if sgp_maunt`i' ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss socialgpId IndividualId (EventDate) : egen double birth1=max(birth)
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

save child_maunt_`i', replace

use child_maunt_`i',clear


sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace sgp_maunt`i'=sgp_maunt`i'[_N] if EventCodemaunt`i'==9 & EventCodemaunt`i'[_N]==9 & _n==_N-1
sort hdss IndividualId EventDate EventCode

sort hdss IndividualId EventDate 
capture drop dup_e
sort hdss IndividualId EventDate EventCode
 bys hdss IndividualId EventDate EventCode EventCodemaunt`i' sgp_maunt`i': gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

/*Indicateur de présence*/

count if socialgpId=="" & sgp_maunt`i'==""
/*Indicateur de présence*/
capture drop coresidmaunt`i'
gen coresidmaunt`i' = (socialgpId==sgp_maunt`i')

cd maunts
*123157 naissances
save child_maunt_`i', replace
cd ..
}






