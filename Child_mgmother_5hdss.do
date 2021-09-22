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
	
		
/****************CREATING Child dataset with mgmotherId ***************/
use  familly_final_5HDSS.dta, clear
*corrections à reverser dans la preparation des données
drop if mgmotherId=="unk"
drop if mgmotherId=="yama"
drop if mgmotherId=="---------"
duplicates drop hdss IndividualId  mgmotherId,force
bys mgmotherId : gen nb_children = _N

ta nb_children

drop if nb_children>123
*56,118 observations deleted

*rename individualid IndividualId 
rename mgmotherId mgmotherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId mgmotherid DoBMGM hdss
*ds,has(type mgmotherid)
keep if mgmotherid!=" "
keep if mgmotherid!=""
*0 deleted

rename IndividualId ChildId
rename mgmotherid mgMotherId
sort mgMotherId ChildId
rename ChildId IndividualId
save mgmother_childID_sahel, replace

use residency_sahel, clear

* import mgmotherId in the core residency file
merge m:1 hdss IndividualId  using mgmother_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel_MGM, replace


/****************Create mgmother_children data*************/
use child_sahel_MGM, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook mgMotherId
**Uniqued FatherId =50,179
keep IndividualId mgMotherId DoB hdss
duplicates drop
rename IndividualId ChildId
rename mgMotherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(IndividualId hdss) j(child_rank)

save mgmother_children_sahel, replace

***********Merge***Childmgmother data with mgmother Residency data***********/
use residency_sahel, clear
merge m:1 hdss IndividualId using mgmother_children_sahel.dta
*drop DoB*
rename _merge mgmotherdata
lab def mgmotherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val mgmotherdata mgmotherdata
codebook IndividualId if mgmotherdata!=1
*122,976
keep if mgmotherdata!=1
* 207,160 mgmothers 
tab mgmotherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

replace EventDate=last_record_date if mgmotherdata==2 	
replace EventCode=9 if mgmotherdata==2


* to check that all EventDate end up 1 Jan 2013 except for non-resident mgmothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*drop if maxEventDate==.
drop maxEventDate 
rename residence residenceMGM
rename socialgpid  socialgpidMGM
rename DoB DoBMGM
bys IndividualId: replace DoBMGM = DoBMGM[_n-1] if missing(DoBMGM) & _n > 1 
bys IndividualId: replace DoBMGM = DoBMGM[_N]

count if DoBMGM==.

save mgmother_sahel, replace


/************Child with event history of the mgmother***********/

use mgmother_sahel, clear

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

rename EventCode EventCodeMGM
rename EventDate EventDateMGM
rename IndividualId mgMotherId
*rename DoD DoDMGM
rename ChildId IndividualId
recode residenceMGM .=0

 
order IndividualId child_rank mgMotherId EventDateMGM EventCodeMGM 
sort IndividualId EventDateMGM EventCodeMGM

* to check that all EventDate end up 1 Jan 2013 except for non-resident mgmothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childMGM_sahel,replace


/***********************TMERGE*******************************/
capture erase child_mgmother_sahel.dta
clear
capture erase child_mgmother_sahel.dta
tmerge IndividualId child_sahel_MGM(EventDate) childMGM_sahel(EventDateMGM) ///
		child_mgmother_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodeMGM = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_mgmother_sahel
count if mgmotherdata==2

count if socialgpidMGM ==""
count if EventDate !=DoB & EventCode ==2
*488

replace DoB = EventDate if EventCode ==2

drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

count if socialgpid=="" & socialgpidMGM==""
/*Indicateur de présence*/
gen coresidMGM = (socialgpid==socialgpidMGM)

*123157 naissances
save child_mgmother_sahel, replace




