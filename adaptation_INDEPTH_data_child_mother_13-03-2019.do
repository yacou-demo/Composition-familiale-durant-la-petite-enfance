* PROGRAM TO PREPARE DATA FOR CHILD MORTALITY HISTORY ANALYSIS
* Prepared by Yacouba Compaoré and Philippe Bocquier 31-01-2019
* Revised 28/05/2019 with 2018 dataset
* Cleaned with PrepareData2018.do

* Methodology updates discussed in Jo’burg in January 2019:
* DONE 2.	Extension to different OBE for each site (not just one date for all sites)
* DONE 4.	For maternal migration status, change to 5 years rather than 10 as being permanent resident 
* DONE 5.	Account for periods before and after death of younger and older siblings

* Change to your own suitable directory
cd "C:\Users\bocquier\Documents\INDEPTH\MADIMAH\MADIMAH 3 Child Mig\2018 analysis\"

use ConsolidatedData2018_analysis.dta,clear
capture lab drop CentreLab
encode CentreId, gen(CentreLab)
capture drop CountryId
recode CentreLab (1 2 3=1 "Burkina Faso") (4=2 "Cote d'Ivoire") (5 6 7 8 9 10=3 "Ethiopia") ///
	(11 12 13=4 "Ghana") (14=5 "Gambia") (15 16=7 "Kenya") ///
	(17=8 "Malawi") (18=9 "Mozambique") (19=10 "Nigeria") (20 21 22=11 "Senegal") ///
	(23 24 25=12 "Tanzania") (26=13 "Uganda") (27 28 29= 14 "South Africa"), gen(CountryId)
capture drop SubContinent
recode Country (1 2 4 5 10 11=1 "West Africa") (3 7 12=2 "East Africa") ///
	(8 9 14=3 "Southern Africa"), gen(SubContinent)
capture drop concat_IndividualId
egen concat_IndividualId=concat(CountryId CentreId IndividualId)
order CountryId SubContinent CentreId CentreLab LocationId concat_IndividualId IndividualId
save ConsolidatedData2018_analysis.dta, replace

* correction for UG011 (reverse coding of Sex)
replace Sex=cond(Sex==1,2,1) if CentreId=="UG011"
compress

* TIME-VARYING COVARIATE FOR 6-MONTH PERIOD BEFORE DoB OF CHILDREN BORN IN HDSS
*Create an extra line for 3-month pregnant event (DoB - 6 months)
sort concat_IndividualId EventDate
expand 2 if EventCode==2, gen(duplicatep)

*Delete information on second row
foreach var of varlist EventDate EventCode{
	bys concat_IndividualId : replace `var'=. if duplicatep==1
}

*Replace dates of birth with (DoB - 6 months) for the duplicates
display %20.0f (365.25/2)*24*60*60*1000 // 15778800000 = 6 months in milliseconds
bys concat_IndividualId : replace EventDate=(DoB -15778800000) if duplicatep==1
bys concat_IndividualId : replace EventCode=11 if duplicatep==1

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 8"-6mDTH" 9 "OBE" 10 "DLV" 11"PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab

* To get the same OBE for all individuals of the same HDSS
drop if EventCode==30 	// drop "period" event (e.g. 1st Jan 2000)
drop calendar_*			// and corresponding variables
drop censor_*
drop duplicatep

by CentreId (EventDate), sort: gen last_obs = (_n == _N)
gen double last_record_date = EventDate if last_obs==1
format last_record_date %tC
bysort CentreId (EventDate): replace last_record_date = last_record_date[_N]
sort concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1
* 219,595 individuals whose records did not end the same OBE as others in HDSS 
drop duplicate
drop last_obs
sort concat_IndividualId
save residency_pregnancy.dta, replace
		
/****************CREATING dataset with MotherId ***************/
use ConsolidatedData2018_analysis.dta, clear
keep CountryId CentreId MotherId 
keep if MotherId!=.
egen concat_MotherId =concat(CountryId CentreId MotherId)
duplicates drop concat_MotherId, force 
rename concat_MotherId concat_IndividualId
sort concat_IndividualId
merge 1:m concat_IndividualId using ConsolidatedData2018_analysis.dta
keep if _merge==3
rename DoB DoB_mother
rename concat_IndividualId concat_MotherId
keep CountryId CentreId concat_MotherId  DoB_mother
duplicates drop
sort CountryId CentreId concat_MotherId  
save Mother, replace 

use ConsolidatedData2018_analysis.dta,clear
egen concat_MotherId =concat(CountryId CentreId MotherId)
sort concat_MotherId
merge m:1 concat_MotherId using Mother.dta
keep if _merge==3 // select only children with identified mothers
keep CountryId CentreId concat_IndividualId DoB Sex EventCode concat_MotherId DoB_mother
sort CountryId CentreId concat_MotherId concat_IndividualId 
* Keep only episodes of BTH 
* => Delete children with MotherId but not born in the HDSS
drop if EventCode!=2
* Delete women with more than 15 children and MotherId missing
capture drop nb_children
bysort CountryId CentreId concat_MotherId (concat_IndividualId): ///
			egen nb_children = sum(EventCode==2) 

tab nb_children CentreId if nb_children>15 & nb_children!=.
/* 
nb_childre |  CentreId
         n |     SN013 |     Total
-----------+-----------+----------
        16 |        16 |        16 
-----------+-----------+----------
     Total |        16 |        16 
*/
sort concat_IndividualId
save Children_Mother, replace

use residency_pregnancy, clear
drop MotherId DeliveryId
* import MotherId in the core (residency + pregnancy) file
merge m:1 concat_IndividualId using Children_Mother.dta
keep if _merge==3
drop _merge
sort concat_IndividualId EventDate EventCode

capture drop maxEventDate
bysort concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate/(1000*60*60*24))
format %td maxEventDate
tab maxEventDate, miss // number of episodes by maximum OBE
/*
maxEventDat |
          e |      Freq.     Percent        Cum.
------------+-----------------------------------
  01jan2012 |     50,085        2.19        2.19
  01jan2013 |     65,929        2.88        5.07
  01jan2015 |    744,296       32.51       37.57
  01jan2016 |    698,638       30.51       68.09
  01jan2017 |    730,741       31.91      100.00
------------+-----------------------------------
      Total |  2,289,689      100.00
*/
codebook concat_IndividualId

*Unique child ID: 	605,679
codebook concat_MotherId
*Unique Mother ID: 	362,919

*************Create Mother_Children data in wide format with child rank************
keep concat_IndividualId concat_MotherId DoB DoB_mother
duplicates drop
rename concat_IndividualId concat_ChildId
rename concat_MotherId concat_IndividualId
sort concat_IndividualId
bysort concat_IndividualId (DoB) : gen child_rank = _n
reshape wide concat_ChildId DoB, i(concat_IndividualId) j(child_rank)
save Mother_Children, replace


************** BEGIN: Merge Residency data with Mother_Children to get a mother file***********
use residency_pregnancy, clear
merge m:1 concat_IndividualId using Mother_Children.dta
drop concat_ChildId*
drop DoB1-DoB16
keep if _merge==3
drop _merge
drop MotherId DeliveryId
drop DoB

* to check that all EventDate end up same 1 Jan 
capture drop maxEventDate
bysort concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate/(1000*60*60*24))
format maxEventDate %td
tab maxEventDate, miss
compare maxEventDate last_record_date
drop maxEventDate 

* Create date of death of the mother
capture drop deadMO
bysort concat_IndividualId (EventDate): egen double deadMO = max(EventCode==7)
replace deadMO=. if deadMO==0
capture drop DoDMO
bysort concat_IndividualId (EventDate): egen double DoDMO = max(deadMO*EventDate*(EventCode==7))
format DoDMO %tC

**Create an extra line 6 month before mother's death 
sort concat_IndividualId EventDate EventCode
capture drop duplicated
expand 2 if EventCode==7, gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
* Replace with date 6 months before death
display %20.0f 30.4375*24*60*60*1000*6 // 6 months in milliseconds
bys concat_IndividualId : replace EventDate=(DoDMO -15778800000) if duplicated==1
* Replace code 
bys concat_IndividualId : replace EventCode=80 if duplicated==1
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId (EventDate EventCode): replace residence=residence[_n+1] ///
		if EventCode==80 & EventCode[_n+1]!=7

**Create an extra line 6 month after mother's death 
sort concat_IndividualId EventDate
capture drop duplicated
expand 2 if EventCode==7,gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
bys concat_IndividualId : replace EventDate=(DoDMO + 15778800000) if duplicated==1
bys concat_IndividualId : replace EventCode=89 if duplicated==1
label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 89 "+6mDTH" 9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
drop duplicated
replace residence=0 if EventCode==81
capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB_mother, EventDate[_n-1])
format datebeg %tC

capture drop censort_DTH6MO
gen censort_DTH6MO = (EventCode==81)
label var censort_DTH6MO "6 month after mother death"

stset EventDate if deadMO==1 & (EventCode==89 | EventCode==9 | residence==1), id(concat_IndividualId) failure(censort_DTH6MO==1) time0(datebeg) ///
				origin(time DoDMO-15778800000) scale(31557600000) 
capture drop mdth6m_3m_15j_15j_3m_6m
stsplit mdth6m_3m_15j_15j_3m_6m , at(0 0.25 .45833333 .54166667 .54166667 .75)
replace mdth6m_3m_15j_15j_3m_6m=6 if mdth6m_3m_15j_15j_3m_6m==. & EventDate>DoDMO
stset, clear
drop censort_DTH6MO
capture drop MO_DTH_TVC
recode mdth6m_3m_15j_15j_3m_6m (0=1 "-6m to -3m MO DTH")(.25=2 "-3m to -15d MO DTH") ///
			(.45833333 = 3 "+/- 15d MO DTH") (.5416667=4 "15d to 3m MO DTH") ///  
			(.75=5 "3m to 6m after MO DTH") (6=6 "6m&+ MO DTH") (.=0 "mother alive or <=-6m MO DTH"),gen(MO_DTH_TVC) label(MO_DTH_TVC)
lab var MO_DTH_TVC "Mother's death TVC"
sort concat_IndividualId EventDate EventCode

replace EventCode=81 if MO_DTH_TVC==1
replace EventCode=82 if MO_DTH_TVC==2 & EventCode==7
replace EventCode=87 if MO_DTH_TVC==3 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=88 if MO_DTH_TVC==4 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=89 if MO_DTH_TVC==5 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=7 if EventDate==DoDMO

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 81 "-3mDTH" 82 "-15dDTH" 87 "+15dDTH" 88 "+3mDTH"  89 "+6mDTH" ///
	9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab

drop if EventDate<DoB & (EventCode>=80 & EventCode<90)
drop if EventDate>last_record_date

* CREATE MIGRATION STATUS (time-varying covariate)
* Generate count variable of periods following in-migration
* NB: 	In-migration occurs only after period of non-residence (residence[_n-1]==0)
* 		and not after internal migration (=change of residence within site, i.e. 
*		reconciliation of concat_IndividualId)
cap drop count_inmig 
bysort concat_IndividualId (EventDate): ///
		gen count_inmig=sum(EventCode[_n-1]!=1 & EventCode[_n-1]!=2 ///
		& residence==1 & residence[_n-1]==0) 

* Generate periods according to the duration of residence since last in-migration
* 1. Set the analysis time to duration of residence since last in-migration only
sort concat_IndividualId count_inmig EventDate 
cap drop concat_IndividualId_inmig 
* Create a new identifier combining individual ID and period after in-migration
* Don't forget to format the new variable as "double"! (or face "trouble"!)
capture drop concat_IndividualId_inmig
gen concat_IndividualId_inmig=concat_IndividualId + string(count_inmig)
* Compute time at in-migration for each period after in-migration
cap drop time_inmig
bysort concat_IndividualId_inmig : gen double time_inmig=datebeg[1] if count_inmig>0
format time_inmig %tC

* 2. Split duration at 6 months, 2 years, 5 years and 10 years for each period after in-migration
* 	Remember 6 months: refer to minimum duration for residence (possible bias! see end of this program)
gen byte censor_death=(EventCode==7)
stset EventDate, id(concat_IndividualId_inmig) failure(censor_death==1) time0(datebeg) ///
				origin(time_inmig) scale(31557600000) if(residence==1)
capture drop inmig6m2_5_10y
stsplit inmig6m2_5_10y if count_inmig>0, at(0.5 2 5 10)
sort concat_IndividualId EventDate
bysort concat_IndividualId: replace EventCode=23 if EventCode==EventCode[_n+1] ///
		& inmig6m2_5_10y==0 & inmig6m2_5_10y!=inmig6m2_5_10y[_n+1] & concat_IndividualId==concat_IndividualId[_n+1]
bysort concat_IndividualId: replace EventCode=24 if EventCode==EventCode[_n+1] ///
		& inmig6m2_5_10y==0.5 & inmig6m2_5_10y!=inmig6m2_5_10y[_n+1] & concat_IndividualId==concat_IndividualId[_n+1]
bysort concat_IndividualId: replace EventCode=25 if EventCode==EventCode[_n+1] ///
		& inmig6m2_5_10y==2 & inmig6m2_5_10y!=inmig6m2_5_10y[_n+1] & concat_IndividualId==concat_IndividualId[_n+1]
bysort concat_IndividualId: replace EventCode=26 if EventCode==EventCode[_n+1] ///
		& inmig6m2_5_10y==5 & inmig6m2_5_10y!=inmig6m2_5_10y[_n+1] & concat_IndividualId==concat_IndividualId[_n+1]
label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 81 "-3mDTH" 82 "-15dDTH" 87 "+15dDTH" 88 "+3mDTH"  89 "+6mDTH" ///
	9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup" ///
		20 "1Jan" 23 "in6m" 24 "in2y" 25 "in5y" 26 "in10y" 29 "out3y", modify 
	
capture drop migrant_status
recode inmig6m2_5_10y (0 .5=1 "in-mig 0-24m") (2=2 "in-mig 2y-5y") ///
			 (5 10 .=0 "permanent res. or in-mig 5y+") ///
		if residence==1, gen(migrant_statusMO) label(migrant_status)
lab var migrant_statusMO "Mother's migration status"

* Censoring variables are safer recomputed after each stplit 
sort concat_IndividualId EventDate EventCode
cap drop censor_deathMO 
gen censor_deathMO=(EventCode==7) if residence==1
* NB: 	Because we stset with EventDate and time0(datebeg), 
* 		neither EventDate nor datebeg need to be recomputed

drop count_inmig concat_IndividualId_inmig time_inmig
drop censor_death
stset, clear
rename residence residenceMO

compress
save mother, replace
**************END: Merge Residency data with Mother_Children to get a mother file***********


/************Child with event history of the mother***********/
use mother, clear
merge m:1 concat_IndividualId using Mother_Children.dta
drop _merge
* corrections of some mothers with the "wrong" sex
// ATTENTION: In MW011 about equal number of "mothers" and "fathers" 
// 			  Probable coding error or registered both fathers and mothers
//			  Exclude MW011 from analysis?
drop Sex

capture drop episode
gen episode=_n
reshape long concat_ChildId DoB, i(episode) j(child_rank) // ATTENTION: this takes time!
drop if concat_ChildId=="" | concat_ChildId==" "
drop episode
capture drop maxEventDate
capture drop datebeg
order CountryId SubContinent CentreId CentreLab LocationId concat_IndividualId child_rank 
rename EventCode EventCodeMO
rename EventDate EventDateMO
rename concat_IndividualId MotherId
rename concat_ChildId concat_IndividualId
order CountryId SubContinent CentreId CentreLab LocationId concat_IndividualId child_rank MotherId EventDateMO EventCodeMO 	
sort concat_IndividualId EventDateMO EventCodeMO
save childMO, replace

use residency_pregnancy.dta, clear
merge m:1 concat_IndividualId using Children_Mother
keep if _merge==3

sort concat_IndividualId EventDate EventCode
* Create date of death of the child
capture drop dead
bysort concat_IndividualId (EventDate): egen dead = max(EventCode==7)
replace dead=. if dead==0
capture drop DoD
bysort concat_IndividualId (EventDate): egen double DoD = max(dead*EventDate*(EventCode==7))
format DoD %tC

**Create an extra line 6 month before child's death 
sort concat_IndividualId EventDate EventCode
capture drop duplicated
expand 2 if EventCode==7, gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
* Replace with date 6 months before death
display %20.0f 30.4375*24*60*60*1000*6 // 6 months in milliseconds
bys concat_IndividualId : replace EventDate=(DoD -15778800000) if duplicated==1
* Replace code 
bys concat_IndividualId : replace EventCode=80 if duplicated==1
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId (EventDate EventCode): replace residence=residence[_n+1] ///
		if EventCode==80 & EventCode[_n+1]!=7

**Create an extra line 6 month after child's death 
sort concat_IndividualId EventDate
capture drop duplicated
expand 2 if EventCode==7, gen(duplicated)
* Delete information on duplicated row
foreach var of varlist EventDate EventCode {
	bys concat_IndividualId : replace `var'=. if duplicated==1
}
bys concat_IndividualId : replace EventDate=(DoD + 15778800000) if duplicated==1
bys concat_IndividualId : replace EventCode=89 if duplicated==1
label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 89 "+6mDTH" 9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
drop duplicated
replace residence=0 if EventCode==81
capture drop datebeg
sort concat_IndividualId EventDate EventCode
qui by concat_IndividualId: gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tC

capture drop censort_DTH6
gen censort_DTH6 = (EventCode==81)
label var censort_DTH6 "6 month after child death"

stset EventDate if dead==1 & (EventCode==89 | EventCode==9 | residence==1), id(concat_IndividualId) failure(censort_DTH6==1) time0(datebeg) ///
				origin(time DoD-15778800000) scale(31557600000) 
capture drop mdth6m_3m_15j_15j_3m_6m
stsplit mdth6m_3m_15j_15j_3m_6m , at(0 0.25 .45833333 .54166667 .54166667 .75)
replace mdth6m_3m_15j_15j_3m_6m=6 if mdth6m_3m_15j_15j_3m_6m==. & EventDate>DoD
stset, clear
drop censort_DTH6
capture drop DTH_TVC
recode mdth6m_3m_15j_15j_3m_6m (0=1 "-6m to -3m  DTH")(.25=2 "-3m to -15d  DTH") ///
			(.45833333 = 3 "+/- 15d  DTH") (.5416667=4 "15d to 3m  DTH") ///  
			(.75=5 "3m to 6m after  DTH") (6=6 "6m&+  DTH") (.=0 "child alive or <=-6m  DTH"), gen(DTH_TVC) label(DTH_TVC)
lab var DTH_TVC "child's death TVC"
sort concat_IndividualId EventDate EventCode

replace EventCode=81 if DTH_TVC==1
replace EventCode=82 if DTH_TVC==2 & EventCode==7
replace EventCode=87 if DTH_TVC==3 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=88 if DTH_TVC==4 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=89 if DTH_TVC==5 & (EventCode==89 | EventCode==9) & EventDate<last_record_date
replace EventCode=7 if EventDate==DoD

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
	7 "DTH" 80 "-6mDTH" 81 "-3mDTH" 82 "-15dDTH" 87 "+15dDTH" 88 "+3mDTH"  89 "+6mDTH" ///
	9 "OBE" 10 "DLV" 11 "PREGNANT" 18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab

drop if EventDate<DoB & (EventCode>=80 & EventCode<90)
drop if EventDate>last_record_date

drop MotherId DeliveryId concat_MotherId DoB_mother _merge
sort concat_IndividualId EventDate EventCode
save child, replace

/*********TMERGE child file with mother variables file *******************************/
clear
capture erase child_mother.dta
tmerge concat_IndividualId child(EventDate) childMO(EventDateMO) ///
		child_mother(EventDate_final)
		
capture drop datebeg

format EventDate_final %tC
drop EventDate 
rename EventDate_final EventDate

order CountryId SubContinent CentreId CentreLab LocationId concat_IndividualId EventDate EventCode
sort concat_IndividualId EventDate EventCode

replace EventCode = 18 if _File==2
replace EventCodeMO = 18 if _File==1

rename _File child_mother_file

save child_mother, replace

* checks:
capture drop datebeg
bysort concat_IndividualId (EventDate): gen double datebeg=cond(_n==1,DoB,EventDate[_n-1])
format datebeg %tC
sort concat_IndividualId EventDate EventCode
cap drop censor_death
gen byte censor_death=(EventCode==7) if residence==1

stset EventDate if residence==1, id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time DoB+(31557600000*5)+212000000) scale(31557600000)

cap drop lastrecord
qui bys concat_IndividualId (EventDate): gen byte lastrecord=(_n==_N) 
tab CentreId if lastrecord==1 
tab CentreId if censor_death==1 & _st==1

clear


