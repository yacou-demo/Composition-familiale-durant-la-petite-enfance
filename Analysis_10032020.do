use final_dataset_analysis_des,clear

capture drop censor_death 
gen censor_death=(EventCode==7) if residence==1
sort concat_IndividualId EventDate

sort hdss IndividualId EventDate EventCode
capture drop datebeg
bysort  hdss IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %td

capture drop lastrecord
sort hdss IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 



stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) exit(time .) scale(365.25)

sort hdss IndividualId EventDate EventCode	
capture drop fifthbirthday
*display %20.0f (5*365.25*24*60*60*1)+212000 /*why 212000000? */ /*(2 days)*/
* 158000000000
stsplit fifthbirthday, at(5.001) 

sort hdss IndividualId EventDate EventCode	
drop if fifthbirthday>0 & fifthbirthday!=.


sort concat_IndividualId EventDate
bys concat_IndividualId : replace EventCode=9 if _n==_N


capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId socialgpId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1


capture drop dead
bysort concat_IndividualId (EventDate): egen double dead = max(EventCode==7)
replace dead=. if dead==0
capture drop DoD
bysort concat_IndividualId (EventDate): egen double DoD = max(dead*EventDate*(EventCode==7))
format DoD %td
* Censure à la date de décès
drop if EventDate > DoD




capture drop censor_death 
gen censor_death=(EventCode==7) if residence==1
sort concat_IndividualId EventDate

sort hdss IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %td

capture drop lastrecord
sort hdss IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 


stset EventDate if residence==1 , id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB) exit(time .) scale(365.25)

		
capture drop MigDead*
gen byte MigDeadMO=(1+residenceMO+2*DeadMO)

recode MigDeadMO (4 = 3)
lab def MigDeadMO 1"mother non resident" 2 "mother res" 3 "mother dead" 4 "mother res dead",  modify	
		
*Description of the data
stdes /*describe survival-time data*/

stsum /*summarize survival-time data*/


*configuration by presence of parents [Première configuration]
capture drop hhtype_1
recode hh_type (10/25=1) (30/45 = 2) (50/65 = 3) (0 71/85 = 4),gen(hhtype_1)
label define hhtype_1 1"Single Mother" 2"Single Father" 3"Couple" 4"No parents"





label val hhtype_1 hhtype_1
tab  hhtype_1 hdss,col
tab  hhtype_1 hdss [iw=(_t-_t0)],col
tab  hh_type hdss [iw=(_t-_t0)],col

* Environnement familial des enfants à la naissance
ta hh_type hdss if EventCode==2,col
tab  hhtype_1 hdss  if EventCode==2,col
graph hbar, over (hhtype_1) over(hdss, sort(1))  asyvars stack
graph bar if EventCode==2,  over(hhtype_1, sort(1)) over (hdss) asyvars stack
graph bar (count)  , over(hdss) over(hhtype_1, sort(1)) 

graph hbar if EventCode==2, over(hhtype_1, sort(1)) 



graph bar prev_exp tenure, over(occ5) percentages stack

capture drop hhtype_2
recode hh_type (11 14 = 14 ) (12 15 = 15) (13 16 = 16) ///
               (11 14 = 14 ) (12 15 = 15) (13 16 = 16) ///
			   (11 14 = 14 ) (12 15 = 15) (13 16 = 16) ///
			   ,gen (hhtype_2)

label define hhtype_1 ///
0"No related" ///
10"Single mother (SM)" ///
14"SM with only GM" ///
15"SM with only GF" ///
16"SM with both GM & GF" ///
,modify
label val hhtype_1 hhtype_1

