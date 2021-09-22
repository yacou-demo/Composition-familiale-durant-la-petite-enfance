*-------------------------------------------------------------------------------
                  **Child - Paternal aunts**
*-------------------------------------------------------------------------------

* Remove the existing folder (puncles)
shell rd "puncles"  /s /q 

* Create it again in order to store the files maternal aunts file
mkdir puncles

forval i=1/20{
	
/****************CREATING Child dataset with puncleid ***************/
use  residency_final_5HDSS_res.dta,clear

*modify
drop if socialgpid=="."
drop if socialgpid==""
drop if socialgpid==" "
tostring hdss, replace

*Modif 210420
gen hdss_1 =""
replace hdss_1 = "GM011" if  hdss==1
replace hdss_1 = "BF041" if  hdss==2
replace hdss_1 = "BF021" if  hdss==3
replace hdss_1 = "SN011" if  hdss==4
replace hdss_1 = "SN012" if  hdss==5

drop hdss
rename hdss_1 hdss
capture drop concat_IndividualId 
egen concat_IndividualId = concat(hdss IndividualId)
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 by concat_IndividualId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1



*Create an extra line for pregnant event (DoB - 6 months)
sort concat_IndividualId EventDate

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
sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bys hdss concat_IndividualId : replace EventCode=9 if _n==_N


capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save residency_sahel.dta, replace

use  familly_final_5HDSS.dta, clear

drop if socialgpId=="."
drop if socialgpId==""
drop if socialgpId==" "
*Modif 210420
gen hdss_1 =""
replace hdss_1 = "GM011" if  hdss==1
replace hdss_1 = "BF041" if  hdss==2
replace hdss_1 = "BF021" if  hdss==3
replace hdss_1 = "SN011" if  hdss==4
replace hdss_1 = "SN012" if  hdss==5

drop hdss
rename hdss_1 hdss
capture drop concat_IndividualId 
egen concat_IndividualId = concat(hdss IndividualId)


foreach var of varlist motherId fatherId mgmotherId mgfatherId pgfatherId ///
pgmotherId puncleid_ego* paunt_ego* muncleid_ego* maunt_ego* {
capture drop  concat_`var'
egen concat_`var' = concat(hdss `var') 
replace concat_`var' ="" if `var'==""
replace concat_`var' ="" if `var'==" "
replace concat_`var' ="" if `var'=="unk"
replace concat_`var' ="" if `var'=="yama"
replace concat_`var' ="" if `var'=="---------"
drop `var'
rename concat_`var' `var'
}


*corrections à reverser dans la preparation des données
drop if puncleid_ego`i'=="unk"
drop if puncleid_ego`i'=="yama"
drop if puncleid_ego`i'=="---------"
duplicates drop   concat_IndividualId  puncleid_ego`i',force
bys puncleid_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename puncleid_ego`i' puncleid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep concat_IndividualId puncleid`i' DoB_puncle`i' hdss  socialgpId 
*ds,has(type puncleid)
keep if puncleid`i'!=" "
keep if puncleid`i'!=""
*0 deleted

rename concat_IndividualId ChildId
rename puncleid`i' PuncleId`i'
sort PuncleId`i' ChildId
rename ChildId concat_IndividualId
save puncle`i'_childID_sahel, replace


use residency_sahel, clear
rename socialgpid socialgpId
* import puncleid in the core residency file
*modif
merge m:1 concat_IndividualId  using puncle`i'_childID_sahel.dta
sort concat_IndividualId EventDate EventCode

keep if _merge==3
keep if _merge==3
sort hdss concat_IndividualId EventDate EventCode

count if EventDate==.

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. 
bys concat_IndividualId  : replace last_record_date=21185  if EventDate==. 
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. 
bys concat_IndividualId  : replace last_record_date=20454  if EventDate==. 
bys concat_IndividualId  : replace last_record_date=21185  if EventDate==.
count if EventDate==.

*modif
replace EventDate = last_record_date if EventDate==.

capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

*modif
* Need recoding for these individuals
sort hdss  concat_IndividualId EventDate EventCode
bys hdss  concat_IndividualId : replace EventCode=9 if _n==_N

*modif 
drop if EventCode==.
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_puncle`i', replace


/****************Create puncle_children data*************/
use child_sahel_puncle`i', clear
codebook concat_IndividualId
**Uniqued IndiId  =130,051
codebook PuncleId`i'
**Uniqued PuncleId =50,179
keep concat_IndividualId PuncleId`i' DoB hdss 

duplicates drop concat_IndividualId  PuncleId`i' DoB ,force
rename concat_IndividualId ChildId
rename  PuncleId`i' concat_IndividualId
sort concat_IndividualId
bysort concat_IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(concat_IndividualId ) j(child_rank)
save puncle`i'_children_sahel, replace



***********Merge***Childpuncle data with puncle Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1   concat_IndividualId using puncle`i'_children_sahel.dta
*drop DoB*
rename _merge puncle`i'data
lab def puncle`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val puncle`i'data puncle`i'data
codebook concat_IndividualId if puncle`i'data!=1
*122,976
keep if puncle`i'data!=1
* 105,181    puncles 
tab puncle`i'data

 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"


replace EventDate=last_record_date if puncle`i'data==2 		
replace EventCode=9 if puncle`i'data==2


capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
bys  concat_IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId : replace EventCode=9 if _n==_N


* to check that all EventDate end up 1 Jan 2013 except for non-resident puncles
capture drop maxEventDate
bysort concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence res_puncle`i'
rename socialgpId  sgp_puncle`i'
rename DoB DoB_puncle`i'
bys concat_IndividualId: replace DoB_puncle`i' = DoB_puncle`i'[_n-1] if missing(DoB_puncle`i') & _n > 1 
bys concat_IndividualId: replace DoB_puncle`i' = DoB_puncle`i'[_N]

count if DoB_puncle`i'==.
save puncle`i'_sahel, replace

use puncle`i'_sahel, clear

bysort concat_IndividualId (EventDate): gen IndividualId_ep = concat_IndividualId+string(EventDate) + string(_n) + hdss
*bysort IndividualId (EventDate): gen a = _n 
reshape long ChildId, i(IndividualId_ep) j(child_rank)

order IndividualId_ep ChildId 
replace gender=2 if gender==1 /*added*/
*3,856
*drop gender
drop if ChildId == ""
drop if ChildId == " "

drop IndividualId_ep
codebook ChildId
*3,944,319(unique ChildId 246,543)

rename EventCode EventCodepuncle`i'
rename EventDate EventDatepuncle`i'
rename concat_IndividualId PuncleId`i'

rename ChildId concat_IndividualId
recode res_puncle`i' .=0

 
order concat_IndividualId child_rank PuncleId`i' EventDatepuncle`i' EventCodepuncle`i' 
sort concat_IndividualId EventDatepuncle`i' EventCodepuncle`i' 


count if EventDatepuncle`i'==.

bys concat_IndividualId : replace last_record_date=21658  if EventDatepuncle`i'==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDatepuncle`i'==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDatepuncle`i'==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDatepuncle`i'==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDatepuncle`i'==. & hdss=="SN012"



capture drop last_obs last_record_date
by hdss (EventDate), sort: gen double last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %td
bys hdss (EventDate): replace last_record_date = last_record_date[_N]

*1672617600000
sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1
drop duplicate

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bys hdss concat_IndividualId : replace EventCode=9 if _n==_N




* to check that all EventDate end up 1 Jan 2013 except for non-resident puncles
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident puncles
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childpuncle`i'_sahel,replace


/***********************TMERGE*******************************/
capture erase child_puncle`i'_sahel.dta
clear
capture erase child_puncle`i'_sahel.dta
tmerge concat_IndividualId child_sahel_puncle`i'(EventDate) childpuncle`i'_sahel(EventDatepuncle`i') ///
		child_puncle`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodepuncle`i'  = 18 if _File==1

order concat_IndividualId EventDate EventCode
sort hdss concat_IndividualId EventDate EventCode
rename _File child_puncle`i'_sahel
count if puncle`i'data==2

count if sgp_puncle`i' ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort concat_IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

*Corrections
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCode=6 if EventCode[_n-1] ==5 & EventCode==9 & EventDate==EventDate[_n-1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCode=5 if EventCode[_n-1] ==6 & EventCode==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCode=6 if EventCode[_n+1] ==5 & EventCode==9 & EventDate==EventDate[_n+1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCode=5 if EventCode[_n+1] ==6 & EventCode==9 & EventDate==EventDate[_n+1]
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace socialgpId=socialgpId[_n-1] if _n==2 & socialgpId!=socialgpId[_n-1]
sort hdss concat_IndividualId EventDate EventCode

save child_puncle_`i', replace

use child_puncle_`i',clear


*for sgp_puncle
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodepuncle`i'=6 if EventCodepuncle`i'[_n-1] ==5 & EventCodepuncle`i'==9 & EventDate==EventDate[_n-1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodepuncle`i'=5 if EventCodepuncle`i'[_n-1] ==6 & EventCodepuncle`i'==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodepuncle`i'=6 if EventCodepuncle`i'[_n+1] ==5 & EventCodepuncle`i'==9 & EventDate==EventDate[_n+1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodepuncle`i'=5 if EventCodepuncle`i'[_n+1] ==6 & EventCodepuncle`i'==9 & EventDate==EventDate[_n+1]
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace sgp_puncle`i'=sgp_puncle`i'[_n-2] if EventCodepuncle`i'==9 & EventCodepuncle`i'[_n-1]==9 
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace sgp_puncle`i'=sgp_puncle`i'[_N] if EventCodepuncle`i'==9 & EventCodepuncle`i'[_N]==9 & _n==_N-1
sort hdss concat_IndividualId EventDate EventCode


sort hdss concat_IndividualId EventDate 
capture drop dup_e
sort hdss concat_IndividualId EventDate EventCode
 bys hdss concat_IndividualId EventDate EventCode EventCodepuncle`i' sgp_puncle`i': gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpId=="" & sgp_puncle`i'==""

/*Indicateur de présence*/
capture drop coresidpuncle`i'
gen coresidpuncle`i' = (socialgpId==sgp_puncle`i')

cd puncles
*123157 naissances
save child_puncle_`i', replace
cd ..
}






