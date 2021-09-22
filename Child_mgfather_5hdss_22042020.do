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
	
		
/****************CREATING Child dataset with mgFatherId ***************/
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
drop if mgfatherId=="unk"
drop if mgfatherId=="yama"
drop if mgfatherId=="---------"
duplicates drop   concat_IndividualId  mgfatherId,force
bys mgfatherId : gen nb_children = _N

ta nb_children

drop if nb_children>48
*13,338 observations deleted

*rename individualid IndividualId 
rename mgfatherId mgfatherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
*modif
keep concat_IndividualId mgfatherid DoBFA hdss socialgpId
*ds,has(type mgfatherid)
keep if mgfatherid!=" "
keep if mgfatherid!=""
*0 deleted

rename concat_IndividualId ChildId
rename mgfatherid mgFatherId
sort mgFatherId ChildId
rename ChildId concat_IndividualId
*modif
save mgfather_childID_sahel, replace

use residency_sahel, clear
rename socialgpid socialgpId
* import mgFatherId in the core residency file
*modif
merge m:1 concat_IndividualId  using mgfather_childID_sahel.dta
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
save child_sahel_MGF, replace


/****************Create father_children data*************/
use child_sahel_MGF, clear
codebook concat_IndividualId
**Uniqued IndiId  =293,735
codebook mgFatherId
**Uniqued mgFatherId =103,728 
keep concat_IndividualId mgFatherId DoB hdss 
duplicates drop concat_IndividualId mgFatherId DoB ,force
rename concat_IndividualId ChildId
rename mgFatherId concat_IndividualId
sort concat_IndividualId
bysort concat_IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(concat_IndividualId) j(child_rank)

save mgfather_children_sahel, replace

***********Merge***Childfather data with father Residency data***********/
use residency_sahel, clear
rename socialgpid socialgpId
merge m:1   concat_IndividualId using mgfather_children_sahel.dta
*drop DoB*
rename _merge mgfatherdata
lab def mgfatherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val mgfatherdata mgfatherdata
codebook concat_IndividualId if mgfatherdata!=1
*122,976
keep if mgfatherdata!=1
* 105,181    fathers 
tab mgfatherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"


replace EventDate=last_record_date if mgfatherdata==2 	
replace EventCode=9 if mgfatherdata==2



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

*drop if maxEventDate==.
drop maxEventDate 
rename residence residenceMGF
rename socialgpId  socialgpidMGF
rename DoB DoBMGF
bys concat_IndividualId: replace DoBMGF = DoBMGF[_n-1] if missing(DoBMGF) & _n > 1 
bys concat_IndividualId: replace DoBMGF = DoBMGF[_N]

count if DoBMGF==.


save mgfather_sahel, replace


/************Child with event history of the father***********/

use mgfather_sahel, clear

bysort concat_IndividualId (EventDate): gen IndividualId_ep = concat_IndividualId+string(EventDate) + string(_n) + hdss
*bysort IndividualId (EventDate): gen a = _n 
reshape long ChildId, i(IndividualId_ep) j(child_rank)

order IndividualId_ep ChildId 
replace gender=1 if gender==2 /*added*/
*3,856
*drop gender
drop if ChildId == ""
drop if ChildId == " "

drop IndividualId_ep
codebook ChildId
*3,944,319(unique ChildId 246,543)

rename EventCode EventCodeMGF
rename EventDate EventDateMGF
rename concat_IndividualId mgFatherId
*rename DoD DoDFA
rename ChildId concat_IndividualId
recode residenceMGF .=0

 
order concat_IndividualId child_rank mgFatherId EventDateMGF EventCodeMGF 
sort concat_IndividualId EventDateMGF EventCodeMGF


count if EventDateMGF==.
bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"



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




* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

* to check that all EventDate end up 1 Jan 2013 except for non-resident fathers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childMGF_sahel,replace


/***********************TMERGE*******************************/
capture erase child_mgfather_sahel.dta
clear
capture erase child_mgfather_sahel.dta
tmerge concat_IndividualId child_sahel_MGF(EventDate) childMGF_sahel(EventDateMGF) ///
		child_mgfather_sahel(EventDate_final)
			
format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodeMGF = 18 if _File==1

order concat_IndividualId EventDate EventCode
sort hdss concat_IndividualId EventDate EventCode
rename _File child_mgfather_sahel
count if mgfatherdata==2

count if socialgpidMGF ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss concat_IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

save child_father_sahel,replace
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

save child_father_sahel, replace


use child_father_sahel,clear

*for socialgpidFA
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodeMGF=6 if EventCodeMGF[_n-1] ==5 & EventCodeMGF==9 & EventDate==EventDate[_n-1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodeMGF=5 if EventCodeMGF[_n-1] ==6 & EventCodeMGF==9 & EventDate==EventDate[_n-1]
*123157 naissances
sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace EventCodeMGF=6 if EventCodeMGF[_n+1] ==5 & EventCodeMGF==9 & EventDate==EventDate[_n+1]

sort hdss concat_IndividualId EventDate
bys hdss  concat_IndividualId : replace EventCodeMGF=5 if EventCodeMGF[_n+1] ==6 & EventCodeMGF==9 & EventDate==EventDate[_n+1]
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace socialgpidMGF=socialgpidMGF[_n-2] if EventCodeMGF==9 & EventCodeMGF[_n-1]==9 
sort hdss concat_IndividualId EventDate EventCode

sort hdss concat_IndividualId EventDate 
bys hdss  concat_IndividualId : replace socialgpidMGF=socialgpidMGF[_N] if EventCodeMGF==9 & EventCodeMGF[_N]==9 & _n==_N-1
sort hdss concat_IndividualId EventDate EventCode


sort hdss concat_IndividualId EventDate 
capture drop dup_e
sort hdss concat_IndividualId EventDate EventCode
 bys hdss concat_IndividualId EventDate EventCode EventCodeMGF socialgpidMGF: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

count if socialgpid=="" & socialgpidMGF==""
/*Indicateur de présence*/
capture drop coresidMGF
gen coresidMGF = (socialgpId==socialgpidMGF)


save child_mgfather_sahel_clean,replace

