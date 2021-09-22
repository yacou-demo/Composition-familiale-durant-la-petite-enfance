*-------------------------------------------------------------------------------
                  **Child - Maternal uncles**
*-------------------------------------------------------------------------------


* Remove the existing folder (muncles)
shell rd "muncles"  /s /q 

* Create it again in order to store the files maternal aunts file
mkdir muncles

forval i=1/20{
	
/****************CREATING Child dataset with muncleid ***************/
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
drop if muncleid_ego`i'=="unk"
drop if muncleid_ego`i'=="yama"
drop if muncleid_ego`i'=="---------"
duplicates drop   concat_IndividualId  muncleid_ego`i',force
bys muncleid_ego`i' : gen nb_children = _N

ta nb_children

drop if nb_children>85
*56,118 observations deleted

*rename individualid IndividualId 
rename muncleid_ego`i' muncleid`i'

**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep concat_IndividualId muncleid`i' DoB_muncle`i' hdss  socialgpId 
*ds,has(type muncleid)
keep if muncleid`i'!=" "
keep if muncleid`i'!=""
*0 deleted

rename concat_IndividualId ChildId
rename muncleid`i' MuncleId`i'
sort MuncleId`i' ChildId
rename ChildId concat_IndividualId
save muncle`i'_childID_sahel, replace


use residency_sahel, clear
rename socialgpid socialgpId
* import muncleid in the core residency file
*modif
merge m:1 concat_IndividualId  using muncle`i'_childID_sahel.dta
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
save child_sahel_muncle`i', replace


/****************Create muncle_children data*************/
use child_sahel_muncle`i', clear
codebook concat_IndividualId
**Uniqued IndiId  =130,051
codebook MuncleId`i'
**Uniqued MuncleId =50,179
keep concat_IndividualId MuncleId`i' DoB hdss 

duplicates drop concat_IndividualId  MuncleId`i' DoB ,force
rename concat_IndividualId ChildId
rename  MuncleId`i' concat_IndividualId
sort concat_IndividualId
bysort concat_IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(concat_IndividualId ) j(child_rank)
save muncle`i'_children_sahel, replace



***********Merge***Childmuncle data with muncle Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1   concat_IndividualId using muncle`i'_children_sahel.dta
*drop DoB*
rename _merge muncle`i'data
lab def muncle`i'data 1 "missing" 2 "not resident" 3 "matched", modify
lab val muncle`i'data muncle`i'data
codebook concat_IndividualId if muncle`i'data!=1
*122,976
keep if muncle`i'data!=1
* 105,181    muncles 
tab muncle`i'data

 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"


replace EventDate=last_record_date if muncle`i'data==2 		
replace EventCode=9 if muncle`i'data==2


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


* to check that all EventDate end up 1 Jan 2013 except for non-resident muncles
capture drop maxEventDate
bysort concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence res_muncle`i'
rename socialgpId  sgp_muncle`i'
rename DoB DoB_muncle`i'
bys concat_IndividualId: replace DoB_muncle`i' = DoB_muncle`i'[_n-1] if missing(DoB_muncle`i') & _n > 1 
bys concat_IndividualId: replace DoB_muncle`i' = DoB_muncle`i'[_N]

count if DoB_muncle`i'==.
save muncle`i'_sahel, replace

use muncle`i'_sahel, clear

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

rename EventCode EventCodemuncle`i'
rename EventDate EventDatemuncle`i'
rename concat_IndividualId MuncleId`i'

rename ChildId concat_IndividualId
recode res_muncle`i' .=0

 
order concat_IndividualId child_rank MuncleId`i' EventDatemuncle`i' EventCodemuncle`i' 
sort concat_IndividualId EventDatemuncle`i' EventCodemuncle`i' 


count if EventDatemuncle`i'==.

bys concat_IndividualId : replace last_record_date=21658  if EventDatemuncle`i'==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDatemuncle`i'==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDatemuncle`i'==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDatemuncle`i'==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDatemuncle`i'==. & hdss=="SN012"



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident muncles
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident muncles
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childmuncle`i'_sahel,replace


/***********************TMERGE*******************************/
capture erase child_muncle`i'_sahel.dta
clear
capture erase child_muncle`i'_sahel.dta
tmerge concat_IndividualId child_sahel_muncle`i'(EventDate) childmuncle`i'_sahel(EventDatemuncle`i') ///
		child_muncle`i'_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodemuncle`i'  = 18 if _File==1

order concat_IndividualId EventDate EventCode
sort hdss concat_IndividualId EventDate EventCode
rename _File child_muncle`i'_sahel
count if muncle`i'data==2

count if sgp_muncle`i' ==""
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

save child_muncle_`i', replace

use child_muncle_`i',clear


*for sgp_muncle
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodemuncle`i'=6 if EventCodemuncle`i'[_n-1] ==5 & EventCodemuncle`i'==9 & EventDate==EventDate[_n-1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodemuncle`i'=5 if EventCodemuncle`i'[_n-1] ==6 & EventCodemuncle`i'==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodemuncle`i'=6 if EventCodemuncle`i'[_n+1] ==5 & EventCodemuncle`i'==9 & EventDate==EventDate[_n+1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodemuncle`i'=5 if EventCodemuncle`i'[_n+1] ==6 & EventCodemuncle`i'==9 & EventDate==EventDate[_n+1]
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace sgp_muncle`i'=sgp_muncle`i'[_n-2] if EventCodemuncle`i'==9 & EventCodemuncle`i'[_n-1]==9 
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace sgp_muncle`i'=sgp_muncle`i'[_N] if EventCodemuncle`i'==9 & EventCodemuncle`i'[_N]==9 & _n==_N-1
sort hdss concat_IndividualId EventDate EventCode


sort hdss concat_IndividualId EventDate 
capture drop dup_e
sort hdss concat_IndividualId EventDate EventCode
 bys hdss concat_IndividualId EventDate EventCode EventCodemuncle`i' sgp_muncle`i': gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpId=="" & sgp_muncle`i'==""

/*Indicateur de présence*/
capture drop coresidmuncle`i'
gen coresidmuncle`i' = (socialgpId==sgp_muncle`i')

cd muncles
*123157 naissances
save child_muncle_`i', replace
cd ..
}






