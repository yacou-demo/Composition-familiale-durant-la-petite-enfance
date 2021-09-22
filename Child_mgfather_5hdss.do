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
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save residency_sahel.dta, replace
	
		
/****************CREATING Child dataset with mgfatherId ***************/
use  familly_final_5HDSS.dta, clear
*corrections à reverser dans la preparation des données
drop if mgfatherId=="unk"
drop if mgfatherId=="yama"
drop if mgfatherId=="---------"
duplicates drop hdss IndividualId  mgfatherId,force
bys mgfatherId : gen nb_children = _N

ta nb_children

drop if nb_children>123
*56,118 observations deleted

*rename individualid IndividualId 
rename mgfatherId mgfatherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId mgfatherid DoBMGF hdss
*ds,has(type mgfatherid)
keep if mgfatherid!=" "
keep if mgfatherid!=""
*0 deleted

rename IndividualId ChildId
rename mgfatherid mgFatherId
sort mgFatherId ChildId
rename ChildId IndividualId
save mgfather_childID_sahel, replace

use residency_sahel, clear

* import mgfatherId in the core residency file
merge m:1 hdss IndividualId  using mgfather_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_MGF, replace


/****************Create mgfather_children data*************/
use child_sahel_MGF, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook mgFatherId
**Uniqued FatherId =50,179
keep IndividualId mgFatherId DoB hdss
duplicates drop
rename IndividualId ChildId
rename mgFatherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(IndividualId hdss) j(child_rank)

save mgfather_children_sahel, replace

***********Merge***Childmgfather data with mgfather Residency data***********/
use residency_sahel, clear
merge m:1 hdss IndividualId using mgfather_children_sahel.dta
*drop DoB*
rename _merge mgfatherdata
lab def mgfatherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val mgfatherdata mgfatherdata
codebook IndividualId if mgfatherdata!=1
*122,976
keep if mgfatherdata!=1
* 207,160 mgfathers 
tab mgfatherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

replace EventDate=last_record_date if mgfatherdata==2 	
replace EventCode=9 if mgfatherdata==2


* to check that all EventDate end up 1 Jan 2013 except for non-resident mgfathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*drop if maxEventDate==.
drop maxEventDate 
rename residence residenceMGF
rename socialgpid  socialgpidMGF
rename DoB DoBMGF
bys IndividualId: replace DoBMGF = DoBMGF[_n-1] if missing(DoBMGF) & _n > 1 
bys IndividualId: replace DoBMGF = DoBMGF[_N]

count if DoBMGF==.

save mgfather_sahel, replace


/************Child with event history of the mgfather***********/

use mgfather_sahel, clear

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

rename EventCode EventCodeMGF
rename EventDate EventDateMGF
rename IndividualId mgFatherId
*rename DoD DoDMGF
rename ChildId IndividualId
recode residenceMGF .=0

 
order IndividualId child_rank mgFatherId EventDateMGF EventCodeMGF 
sort IndividualId EventDateMGF EventCodeMGF

* to check that all EventDate end up 1 Jan 2013 except for non-resident mgfathers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childMGF_sahel,replace


/***********************TMERGE*******************************/
capture erase child_mgfather_sahel.dta
clear
capture erase child_mgfather_sahel.dta
tmerge IndividualId child_sahel_MGF(EventDate) childMGF_sahel(EventDateMGF) ///
		child_mgfather_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodeMGF = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_mgfather_sahel
count if mgfatherdata==2

count if socialgpidMGF ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

count if socialgpid=="" & socialgpidMGF==""
/*Indicateur de présence*/
gen coresidMGF = (socialgpid==socialgpidMGF)

*123157 naissances
save child_mgfather_sahel, replace




