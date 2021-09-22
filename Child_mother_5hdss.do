use residency_final_5HDSS_res.dta,clear
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
	
		
/****************CREATING Child dataset with MotherId ***************/
use  familly_final_5HDSS.dta, clear
*corrections à reverser dans la preparation des données
drop if motherId=="unk"
drop if motherId=="yama"
drop if motherId=="---------"
duplicates drop hdss IndividualId  motherId,force
bys motherId : gen nb_children = _N

ta nb_children

drop if nb_children>22
*269 
*rename individualid IndividualId 
rename motherId motherid
**CHANGE
*Trouver une solution pour traiter le cas alphanumérique et numérique simultanément
keep IndividualId motherid DoBMO hdss
*ds,has(type motherid)
keep if motherid!=" "
keep if motherid!=""
*246,547

rename IndividualId ChildId
rename motherid MotherId
sort MotherId ChildId
rename ChildId IndividualId
save mother_childID_sahel, replace

use residency_sahel, clear

* import MotherId in the core residency file
merge m:1 hdss IndividualId  using mother_childID_sahel.dta
keep if _merge==3
drop _merge
sort hdss IndividualId EventDate EventCode


capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*replace  center="MISSING" if center==""
save child_sahel, replace


/****************Create mother_children data*************/
use child_sahel, clear
codebook IndividualId
**Uniqued IndiId  =130,051
codebook MotherId
**Uniqued MotherId =50,179
keep IndividualId MotherId DoB hdss
duplicates drop
rename IndividualId ChildId
rename MotherId IndividualId
sort IndividualId
bysort IndividualId (DoB) : gen child_rank = _n
reshape wide ChildId DoB, i(IndividualId hdss) j(child_rank)

save mother_children_sahel, replace

***********Merge***ChildMother data with Mother Residency data***********/
use residency_sahel, clear
merge m:1 hdss IndividualId using mother_children_sahel.dta
*drop DoB*
rename _merge motherdata
lab def motherdata 1 "missing" 2 "not resident" 3 "matched", modify
lab val motherdata motherdata
codebook IndividualId if motherdata!=1
*122,976
keep if motherdata!=1
* 340,389 mothers 
tab motherdata
 gsort  EventDate
bys hdss : replace last_record_date = last_record_date[_n-1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_n+1] if missing(last_record_date) & _n > 1 
bys hdss : replace last_record_date = last_record_date[_N]

replace EventDate=last_record_date if motherdata==2 	
replace EventCode=9 if motherdata==2


* to check that all EventDate end up 1 Jan 2013 except for non-resident mothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss
*drop if maxEventDate==.
drop maxEventDate 
rename socialgpid  socialgpidMO
rename residence residenceMO
rename DoB DoBMO
bys IndividualId: replace DoBMO = DoBMO[_n-1] if missing(DoBMO) & _n > 1 
bys IndividualId: replace DoBMO = DoBMO[_N]

count if DoBMO==.

save mother_sahel, replace


/************Child with event history of the mother***********/



use mother_sahel, clear

bysort IndividualId (EventDate): gen IndividualId_ep = IndividualId+string(EventDate) + string(_n) + string(hdss)
*bysort IndividualId (EventDate): gen a = _n 
reshape long ChildId, i(IndividualId_ep) j(child_rank)

order IndividualId_ep ChildId 
replace gender=2 if gender==1 /*added*/
*18,960 
*drop gender
drop if ChildId == ""
drop if ChildId == " "

drop IndividualId_ep
codebook ChildId
*3,944,319(unique ChildId 246,543)

rename EventCode EventCodeMO
rename EventDate EventDateMO
rename IndividualId MotherId
*rename DoD DoDMO
rename ChildId IndividualId
recode residenceMO .=0
 
order IndividualId child_rank MotherId EventDateMO EventCodeMO 
sort IndividualId EventDateMO EventCodeMO

* to check that all EventDate end up 1 Jan 2013 except for non-resident mothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save childMO_sahel,replace



/***********************TMERGE*******************************/
capture erase child_mother_sahel.dta
clear
capture erase child_mother_sahel.dta
tmerge IndividualId child_sahel(EventDate) childMO_sahel(EventDateMO) ///
		child_mother_sahel(EventDate_final)
			

format EventDate_final %td
drop EventDate 
rename EventDate_final EventDate

replace EventCode = 18 if _File==2
replace EventCodeMO = 18 if _File==1

order IndividualId EventDate EventCode
sort hdss IndividualId EventDate EventCode
rename _File child_mother_sahel
drop if motherdata==2


count if EventDate !=DoB & EventCode ==2
*488
replace DoB = EventDate if EventCode ==2



drop if EventDate < DoB
gen birth = EventCode==2
bysort hdss IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0

*123157 naissances

** Création de la variable de corésidence dans le ménage

*Corrections 
/* A la naissance l'enfant et sa mère sont toujours co-résidents*/
count if  EventCode==2 & socialgpid!=socialgpidMO

replace socialgpid = socialgpidMO if EventCode==2 & socialgpid!=socialgpidMO

/*Indicateur de présence*/
gen coresidMO = (socialgpid==socialgpidMO)
save child_mother_sahel, replace




