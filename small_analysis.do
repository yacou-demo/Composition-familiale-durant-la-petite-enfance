/*
use  child_network_pa_paunt_muncle_maunt,clear
drop DoB1 DoB1* DoB2 DoB2* DoB3 DoB3* ///
     DoB4 DoB4* DoB5 DoB5* DoB6 DoB6* ///
	 DoB7 DoB7* DoB8 DoB8* DoB9 DoB9* motherdata ///
     child_mother_sahel coresidFA ///
	 merge_addmgm appendmgm merge_addpa ///
	 appendpmgm pgmotherdata child_pgmother_sahel ///
	 coresidPGM child_parents_mgparents_pgmother merge_addpgf ///
	 appendpgf merge_addppgf appendppgf ///
	 pgfatherdata child_pgfather_sahel ///
	 coresidPGF child_pa_mgpa_pgpa ///
	 merge1 append_1 merge_1 append__1 ///
	 merge10 append_10 merge_10 append__10 ///
     birth birth1 merge_add append1 ///
	 append2 DoB54 DoB84 append* merge* ///
child_* uncle*  aunt* maunt* muncle* coresid*
compress

save child_network_5hdss,replace
*/
use child_network_5hdss,clear

*Censure à 5 ans
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId : replace EventDate = EventDate+1 ///
if EventCode[_n-1]==5 & EventCode==6 & EventDate==EventDate[_n-1]
bys concat_IndividualId : replace EventDate = EventDate+1 ///
if EventCode[_n-1]==2 & EventCode==7 & EventDate==EventDate[_n-1]

capture drop lastrecord
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 

sort hdss IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double ///
datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %td


stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) exit(time .) scale(365.25)

sort hdss IndividualId EventDate EventCode	
capture drop fifthbirthday
*display %20.0f (5*365.25*24*60*60*1)+212000 /*why 212000000? */ /*(2 days)*/
* 158000000000
stsplit fifthbirthday, at(5.001) 
sort concat_IndividualId EventDate EventCode
order concat_IndividualId EventDate EventCode
edit concat_IndividualId EventDate EventCode _st _d fifthbirthday
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId :replace fifthbirthday=0 if EventCode==2

drop if fifthbirthday>0 



	
sort  concat_IndividualId EventDate EventCode
replace socialgpId=socialgpId[_n-1] if EventCode==18 & EventCode[_n-1]==2
sort  concat_IndividualId EventDate EventCode
count if socialgpId==socialgpId[_n+1] & EventCode==5 & ///
EventCode[_n+1]==6 & EventDate==EventDate[_n+1]

*(1) Sélectionner les enfants nés sous surveillance
sort  concat_IndividualId EventDate EventCode
drop if EventDate < DoB
capture drop birth birth1
gen birth = EventCode==2
bysort concat_IndividualId (EventDate) : egen double birth1=max(birth)
drop if birth1==0
bys concat_IndividualId (EventDate): drop if  EventCode==2 & EventCode[_n-1]==2
bys concat_IndividualId (EventDate) : drop if  EventCode==3 & EventCode[_n-1]==3
bys concat_IndividualId (EventDate): drop if  EventCode==4 & EventCode[_n-1]==4
bys concat_IndividualId (EventDate): drop if  EventCode==5 & EventCode[_n-1]==5
bys concat_IndividualId (EventDate) : drop if  EventCode==6 & EventCode[_n-1]==6

sort hdss IndividualId EventDate 
bys hdss  IndividualId : replace EventDate=21653 if EventDate==21658

*(2) Supprimer les doublons
capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId socialgpId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1
sort concat_IndividualId EventDate
bys concat_IndividualId : replace EventCode=9 if _n==_N

* (3) quelques corrections
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId (EventDate) : replace EventCode = 4 if EventCode==5 & EventCode[_n+1]!=6
bys concat_IndividualId (EventDate) :  replace EventCode = 3 if EventCode==6 & EventCode[_n-1]==4
bys concat_IndividualId (EventDate) :  drop if EventCode==6 & EventCode[_n-1]!=5


*(3) Supprimer les observations après le décès de l'enfant.
capture drop dead
sort concat_IndividualId EventDate EventCode
bysort concat_IndividualId (EventDate): egen double dead = max(EventCode==7)
replace dead=. if dead==0
capture drop DoD
bysort concat_IndividualId (EventDate): egen double DoD = max(dead*EventDate*(EventCode==7))
format DoD %td
drop if EventDate > DoD

*(4) Supprimer les observations après la dernière émigration de l'enfant
capture drop censor_out
bysort concat_IndividualId   :gen censor_out=(EventCode==4) 
replace censor_out=. if censor_out==0

capture drop DoOMG
bysort concat_IndividualId (EventDate): egen double DoOMG = max(censor_out*EventDate)
format DoOMG %td

order concat_IndividualId EventDate EventCode EventDateMO EventCodeMO socialgpId socialgpidMO residence residenceMO
br concat_IndividualId EventDate EventCode DoOMG hdss

capture drop censor_inm
bysort concat_IndividualId   :gen censor_inm=(EventCode==3) 
replace censor_inm=. if censor_inm==0

capture drop DoIMG
bysort concat_IndividualId (EventDate): egen double DoIMG = max(censor_inm*EventDate)
format DoIMG %td


drop if EventDate > DoOMG & DoIMG==. & DoOMG!=.
drop if EventDate > DoOMG & DoIMG<DoOMG
ta hdss last_record_date,nol


sort hdss IndividualId EventDate 
bys hdss IndividualId : replace EventDate = EventDate - 1 if EventCode==6 & EventCode[_n-1]==5
sort hdss IndividualId EventDate EventCode
count if socialgpId==socialgpId[_n+1] & EventCode==5 & EventCode[_n+1]==6 & EventDate==EventDate[_n+1]


**Supprimer socialgpid après la migration ou le décès d'un proche parent

*(3) Supprimer les observations après le décès de l'enfant.
foreach var of varlist EventCodeMO EventCodeFA EventCodeMGF EventCodeMGM  EventCodePGF EventCodePGM {
local w = substr(`"`var'"', 10, .)
capture drop dead`w'
sort concat_IndividualId EventDate 
bysort concat_IndividualId   :gen dead`w'=(EventCode`w'==7) 
replace dead`w'=. if dead`w'==0
capture drop DoD`w'
bysort concat_IndividualId (EventDate): egen double DoD`w' = max(dead`w'*EventDate)
format DoD`w' %td
replace socialgpid`w'="" if EventDate > DoD`w' 
 }


foreach var of varlist EventCodeMO EventCodeFA EventCodeMGF EventCodeMGM  EventCodePGF EventCodePGM {
local w = substr(`"`var'"', 10, .)
capture drop censor_out`w'
sort concat_IndividualId EventDate 
bysort concat_IndividualId   :gen censor_out`w'=(EventCode`w'==4) 
replace censor_out`w'=. if censor_out`w'==0

capture drop DoOMG`w'
bysort concat_IndividualId (EventDate): egen double DoOMG`w' = max(censor_out`w'*EventDate)
format DoOMG`w' %td

capture drop censor_inm`w'
bysort concat_IndividualId   :gen censor_inm`w'=(EventCode`w'==3) 
replace censor_inm`w'=. if censor_inm`w'==0

capture drop DoIMG`w'
bysort concat_IndividualId (EventDate): egen double DoIMG`w' = max(censor_inm`w'*EventDate)
format DoIMG`w' %td

replace socialgpid`w'="" if EventDate > DoOMG`w' & DoIMG`w'==. & DoOMG`w'!=.
replace socialgpid`w'=""  if EventDate > DoOMG`w' & DoIMG`w'<DoOMG`w'
 }

 

 *(3) Supprimer les observations après le décès de l'enfant.
foreach var of varlist EventCodemaunt* EventCodemuncle* EventCodepaunt* EventCodepuncle* {
local w = substr(`"`var'"', 10, .)
capture drop dead`w'
sort concat_IndividualId EventDate 
bysort concat_IndividualId   :gen dead`w'=(EventCode`w'==7) 
replace dead`w'=. if dead`w'==0
capture drop DoD`w'
bysort concat_IndividualId (EventDate): egen double DoD`w' = max(dead`w'*EventDate)
format DoD`w' %td
replace sgp_`w'="" if EventDate > DoD`w' 
 }


foreach var of varlist EventCodemaunt* EventCodemuncle* EventCodepaunt* EventCodepuncle* {
local w = substr(`"`var'"', 10, .)
capture drop censor_out`w'
sort concat_IndividualId EventDate 
bysort concat_IndividualId   :gen censor_out`w'=(EventCode`w'==4) 
replace censor_out`w'=. if censor_out`w'==0

capture drop DoOMG`w'
bysort concat_IndividualId (EventDate): egen double DoOMG`w' = max(censor_out`w'*EventDate)
format DoOMG`w' %td

capture drop censor_inm`w'
bysort concat_IndividualId   :gen censor_inm`w'=(EventCode`w'==3) 
replace censor_inm`w'=. if censor_inm`w'==0

capture drop DoIMG`w'
bysort concat_IndividualId (EventDate): egen double DoIMG`w' = max(censor_inm`w'*EventDate)
format DoIMG`w' %td

replace sgp_`w'="" if EventDate > DoOMG`w' & DoIMG`w'==. & DoOMG`w'!=.
replace sgp_`w'=""  if EventDate > DoOMG`w' & DoIMG`w'<DoOMG`w'
 }

 
 
 **Correction sur les socialgpid
sort concat_IndividualId EventDate
replace socialgpId=socialgpId[_n-1] if socialgpId!=socialgpId[_n-1] & EventCode==EventCode[_n-1] & EventCode==18
replace socialgpId=socialgpId[_n-1] if socialgpId!=socialgpId[_n-1] & EventCode==EventCode[_n-1] & EventCode==9


foreach var of varlist socialgpidMO socialgpidFA socialgpidMGF socialgpidMGM  socialgpidPGF socialgpidPGM {
sort concat_IndividualId EventDate
 local w = substr(`"`var'"', 11, .)
replace socialgpid`w'=socialgpid`w'[_n-1] if socialgpid`w'!=socialgpid`w'[_n-1] & EventCode`w'==EventCode`w'[_n-1] & EventCode==18
replace socialgpid`w'=socialgpid`w'[_n-1] if socialgpid`w'!=socialgpid`w'[_n-1] & EventCode==EventCode[_n-1] & EventCode`w'==9 
}

 foreach var of varlist sgp_* {
 sort concat_IndividualId EventDate
 local w = substr(`"`var'"', 5, .)
replace sgp_`w'=sgp_`w'[_n-1] if sgp_`w'!=sgp_`w'[_n-1] & EventCode`w'==EventCode`w'[_n-1] & EventCode==18
replace sgp_`w'=sgp_`w'[_n-1] if sgp_`w'!=sgp_`w'[_n-1] & EventCode`w'==EventCode`w'[_n-1] & EventCode`w'==9 
}

 
 
*Verif

capture drop censor_death 
gen censor_death=(EventCode==7) if residence==1
sort concat_IndividualId EventDate

sort hdss IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %td

* * Création de la variable corésidence [Parents très proches]
foreach var of varlist EventCodeMO EventCodeFA EventCodeMGF EventCodeMGM  EventCodePGF EventCodePGM {
 local w = substr(`"`var'"', 10, .)

 capture drop coresid`w'
 gen coresid`w' = (socialgpId==socialgpid`w')
 }

 foreach var of varlist EventCodeMO EventCodeFA EventCodeMGF EventCodeMGM  EventCodePGF EventCodePGM {
 local w = substr(`"`var'"', 10, .)
 capture drop Dead`w'
bysort concat_IndividualId (EventDate): gen byte Dead`w'=sum(EventCode`w'[_n-1]==7) 
replace Dead`w'= 1 if Dead`w'>1 & Dead`w'!=. 
replace coresid`w'=0 if Dead`w'==1
 }



* Création de la variable corésidence [Aunts and Uncles]
foreach var of varlist EventCodemaunt* EventCodemuncle* EventCodepaunt* EventCodepuncle* {
 local w = substr(`"`var'"', 10, .)
 capture drop coresid`w'
 gen coresid`w' = (socialgpId==sgp_`w')
 }
 
 * Correction de la variable corésidence après le décès
  foreach var of varlist EventCodemaunt* EventCodemuncle* EventCodepaunt* EventCodepuncle* {
 local w = substr(`"`var'"', 10, .)
 capture drop Dead`w'
bysort hdss IndividualId (EventDate): gen byte Dead`w'=sum(EventCode`w'[_n-1]==7) 
replace Dead`w'= 1 if Dead`w'>1 & Dead`w'!=. 
replace coresid`w'=0 if Dead`w'==1
 }
 

stset EventDate , id(concat_IndividualId) failure(censor_death==1) ///
		time0(datebeg) origin(time DoB)  scale(365.25)

capture drop Dead*
bysort concat_IndividualId (EventDate): gen byte DeadMO=sum(EventCodeMO[_n-1]==7) 
replace DeadMO= 1 if DeadMO>1 & DeadMO!=. 

capture drop MigDead*
gen byte MigDeadMO=(1+residenceMO+2*DeadMO)

recode MigDeadMO (4 = 3)
lab def MigDeadMO 1"mother non resident" 2 "mother res" 3 "mother dead" 4 "mother res dead",  modify	
lab val MigDeadMO MigDeadMO


save final_dataset_paper_1_bis_1,replace



use final_dataset_paper_1_bis_1,clear

 *Coresidence avec au moins une tante maternelle
 capture drop coresid_maunt
 egen coresid_maunt = rowtotal(coresidmaunt*)
 replace coresid_maunt = 1 if coresid_maunt>1
 
*Coresidence avec au moins une tante paternelle
 capture drop coresid_paunt
 egen coresid_paunt = rowtotal(coresidpaunt*)
 replace coresid_paunt = 1 if coresid_paunt>1

 
* Corésidence avec au moins un oncle paternel
 capture drop coresid_puncle
 egen coresid_puncle = rowtotal(coresidpuncle*)
 replace coresid_puncle = 1 if coresid_puncle>1

*Corésidence avec au moins un oncle maternel
 capture drop coresid_muncle
 egen coresid_muncle = rowtotal(coresidmuncle*)
 replace coresid_muncle = 1 if coresid_muncle>1

 
 ****
 capture drop presence
 egen presence = rowtotal( coresidMO coresidFA coresidPGF coresidPGM ///
 coresidMGF coresidMGM  coresid_puncle coresid_paunt coresid_muncle ///
 coresid_maunt)
 
 drop if EventCode==18 & presence==0
 capture drop presence_PVK
 gen presence_PVK = (coresidPGM==1 | coresidPGF==1) 
 
 capture drop presence_MVK
 gen presence_MVK = (coresidMGM==1 | coresidMGF==1) 
 
 capture drop presence_PLK
 gen presence_PLK = (coresid_puncle==1 | coresid_paunt==1) 

 capture drop presence_MLK
 gen presence_MLK = (coresid_muncle==1 | coresid_maunt==1) 
save final_dataset_paper_1_bis_2,replace
 


use final_dataset_paper_1_bis_2,clear
 *Single Mother
 capture drop hh_type
 gen hh_type = 0
 replace hh_type = 10 if coresidMO==1 & presence==1
 replace hh_type = 30 if coresidFA==1 & presence==1
 replace hh_type = 50 if coresidMO==1 & coresidFA==1 
 replace hh_type = 70 if coresidMO==0 & coresidFA==0 & presence>0
 
 ********************
 * Single mother categories
 
 * - single mother with paternal grand mother
 replace hh_type = 11 if coresidMO==1 & coresidPGM==1 & presence==2
 * - single mother with paternal grand father
 replace hh_type = 12 if coresidMO==1 & coresidPGF==1 & presence==2
 replace hh_type= 13 if coresidMO==1 & coresidPGM==1 & coresidPGF==1 & presence==3

 * - single mother with maternal grand mother
 replace hh_type = 14 if coresidMO==1 & coresidMGM==1 & presence==2
 * - single mother with maternal grand father
 replace hh_type = 15 if coresidMO==1 & coresidMGF==1 & presence==2
 replace hh_type = 16 if coresidMO==1 & coresidMGM==1 & coresidMGF==1 & presence==3

 * - single mother with paternal aunt
 replace hh_type = 17 if coresidMO==1 & coresid_paunt==1 & presence==2
 * - single mother with paternal uncle
 replace hh_type = 18 if coresidMO==1 & coresid_puncle==1 & presence==2
 
 replace hh_type= 19 if coresidMO==1 & coresid_puncle==1 & coresid_paunt==1 & presence==3

 * - single mother with maternal grand mother
 replace hh_type = 20 if coresidMO==1 & coresid_maunt==1 & presence==2
 * - single mother with paternal uncle
 replace hh_type = 21 if coresidMO==1 & coresid_muncle==1 & presence==2
 
 replace hh_type=  22 if coresidMO==1 & coresid_muncle==1 & coresid_maunt==1 & presence==3

 *Single parents with paternal vertically and laterally extended kin
  replace hh_type = 23 if coresidMO==1  & presence_PVK==1 & presence_PLK==1 & presence_MVK==0 & presence_MLK==0 & coresidFA==0
  
  *Single parents with maternal vertically and laterally extended kin
  replace hh_type = 24 if coresidMO==1 & presence_MVK==1 & presence_MLK==1 & presence_PVK==0 & presence_PLK==0 & coresidFA==0
   
   * Single mother with complex family composition
 replace hh_type = 25 if  coresidMO==1   & presence_MVK==1 & presence_MLK==1 & presence_PVK==1 & presence_PLK==1  & hh_type==0
 replace hh_type = 25 if  coresidMO==1   &  (presence_MVK==1 | presence_MLK==1) & (presence_PVK==1 | presence_PLK==1)  & hh_type==0

   
  * Single father categories
 
 * - single father with paternal grand mother
 replace hh_type = 31 if coresidFA==1 & coresidPGM==1 & presence==2
 * - single father with paternal grand father
 replace hh_type = 32 if coresidFA==1 & coresidPGF==1 & presence==2
 replace hh_type=  33 if coresidFA==1 & coresidPGM==1 & coresidPGF==1 & presence==3

 * - single father with maternal grand mother
 replace hh_type = 34 if coresidFA==1 & coresidMGM==1 & presence==2
 * - single father with maternal grand father
 replace hh_type = 35 if coresidFA==1 & coresidMGF==1 & presence==2
 replace hh_type= 36 if coresidFA==1 & coresidMGM==1 & coresidMGF==1 & presence==3

 * - single father with paternal aunt
 replace hh_type = 37 if coresidFA==1 & coresid_paunt==1 & presence==2
 * - single father with paternal uncle
 replace hh_type = 38 if coresidFA==1 & coresid_puncle==1 & presence==2
 replace hh_type= 39 if coresidFA==1 & coresid_puncle==1 & coresid_paunt==1 & presence==3

 * - single father with maternal grand mother
 replace hh_type = 40 if coresidFA==1 & coresid_maunt==1 & presence==2
 * - single father with paternal uncle
 replace hh_type = 41 if coresidFA==1 & coresid_muncle==1 & presence==2
 replace hh_type= 42 if coresidFA==1 & coresid_muncle==1 & coresid_maunt==1 & presence==3

 
 *Single parents with paternal vertically and laterally extended kin
  replace hh_type = 43 if coresidFA==1  & presence_PVK==1 & presence_PLK==1 & presence_MVK==0 & presence_MLK==0 & coresidMO==0
  
  *Single parents with maternal vertically and laterally extended kin
  replace hh_type = 44 if coresidFA==1 & presence_MVK==1 & presence_MLK==1 & presence_PVK==0 & presence_PLK==0 & coresidMO==0
 replace hh_type =  45 if coresidFA==1  & presence_MVK==1 & presence_MLK==1 & presence_PVK==1 & presence_PLK==1  
 replace hh_type=   45 if  coresidFA==1   &  (presence_MVK==1 | presence_MLK==1) & (presence_PVK==1 | presence_PLK==1) 

   * Coupleq categories
 
 * - single father with paternal grand mother
 replace hh_type = 51 if  coresidMO==1 & coresidFA==1  & coresidPGM==1 & presence==3
 * - single father with paternal grand father
 replace hh_type = 52 if  coresidMO==1 & coresidFA==1  & coresidPGF==1 & presence==3
 replace hh_type = 53 if  coresidMO==1 & coresidFA==1  & coresidPGF==1 & coresidPGM==1 & presence==4

 * - single father with maternal grand mother
 replace hh_type = 54 if  coresidMO==1 & coresidFA==1  & coresidMGM==1 & presence==3
 * - single father with maternal grand father
 replace hh_type = 55 if  coresidMO==1 & coresidFA==1  & coresidMGF==1 & presence==3
 
 replace hh_type = 56 if  coresidMO==1 & coresidFA==1  & coresidMGF==1 & coresidMGM==1 & presence==4

 * - single father with paternal aunt
 replace hh_type = 57 if  coresidMO==1 & coresidFA==1  & coresid_paunt==1 & presence==3
 * - single father with paternal uncle
 replace hh_type = 58 if  coresidMO==1 & coresidFA==1  & coresid_puncle==1 & presence==3
  replace hh_type = 59 if  coresidMO==1 & coresidFA==1  & coresid_paunt==1 & coresid_puncle==1 & presence==4

 * - single father with maternal grand mother
 replace hh_type = 60 if  coresidMO==1 & coresidFA==1  & coresid_maunt==1 & presence==3
 * - single father with paternal uncle
 replace hh_type = 61 if  coresidMO==1 & coresidFA==1  & coresid_muncle==1 & presence==3
 replace hh_type = 62 if  coresidMO==1 & coresidFA==1  & coresid_maunt==1 & coresid_muncle==1 & presence==4

 *Single parents with paternal vertically and laterally extended kin
 replace hh_type = 63 if  coresidMO==1 & coresidFA==1  & presence_PVK==1 & presence_PLK==1 & presence_MVK==0 & presence_MLK==0 
  
  *Single parents with maternal vertically and laterally extended kin
replace hh_type = 64 if coresidMO==1 & coresidFA==1  & presence_MVK==1 & presence_MLK==1 & presence_PVK==0 & presence_PLK==0  

replace hh_type = 65 if coresidMO==1 & coresidFA==1   & presence_MVK==1 & presence_MLK==1 & presence_PVK==1 & presence_PLK==1 
replace hh_type = 65 if coresidMO==1 & coresidFA==1   &  (presence_MVK==1 | presence_MLK==1) & (presence_PVK==1 | presence_PLK==1) 

 * No parents
 
 * - No parents with paternal grand mother
 replace hh_type = 71 if  coresidMO==0 & coresidFA==0  & coresidPGM==1 & presence==1
 * - No parents with paternal grand father
 replace hh_type = 72 if  coresidMO==0 & coresidFA==0  & coresidPGF==1 & presence==1
 replace hh_type = 73 if  coresidMO==0 & coresidFA==0  & coresidPGM==1 & coresidPGF==1 & presence==2

 * - No parents with maternal grand mother
replace hh_type = 74 if  coresidMO==0 & coresidFA==0  & coresidMGM==1 & presence==1
 * - No parents with maternal grand father
replace hh_type = 75 if  coresidMO==0 & coresidFA==0  & coresidMGF==1 & presence==1
replace hh_type = 76 if  coresidMO==0 & coresidFA==0  & coresidMGM==1 & coresidMGF==1 & presence==2

 * - No parents with paternal aunt
 replace hh_type = 77 if  coresidMO==0 & coresidFA==0  & coresid_paunt==1 & presence==1
 * - No parents with paternal uncle
 replace hh_type = 78 if  coresidMO==0 & coresidFA==0  & coresid_puncle==1 & presence==1
 replace hh_type = 79 if  coresidMO==0 & coresidFA==0  & coresid_paunt==1 & coresid_puncle==1 & presence==2

 * - No parents with maternal grand mother
 replace hh_type = 80 if  coresidMO==0 & coresidFA==0  & coresid_maunt==1 & presence==1
 * - No parents with paternal uncle
 replace hh_type = 81 if  coresidMO==0 & coresidFA==0  & coresid_muncle==1 & presence==1
 replace hh_type = 82 if  coresidMO==0 & coresidFA==0  & coresid_maunt==1 & coresid_muncle==1 & presence==2


replace hh_type = 83 if  coresidMO==0 & coresidFA==0  & presence_PVK==1 & presence_PLK==1 & presence_MVK==0 & presence_MLK==0 
  
  *Single parents with maternal vertically and laterally extended kin
 replace hh_type = 84 if coresidMO==0 & coresidFA==0  & presence_MVK==1 & presence_MLK==1 & presence_PVK==0 & presence_PLK==0  

replace hh_type = 85 if coresidMO==0 & coresidFA==0   & presence_MVK==1 & presence_MLK==1 & presence_PVK==1 & presence_PLK==1  
replace hh_type = 85 if coresidMO==0 & coresidFA==0   &  (presence_MVK==1 | presence_MLK==1) & (presence_PVK==1 | presence_PLK==1) 

 
 
 label define hh_type ///
 0"Not relatives" ///
 10"Single mother" ///
 11"Single mother with only PGM" ///
 12"Single mother with only PGF" ///
 13"Single mother with both PGM & PGF" ///
 14"Single mother with only MGM" ///
 15"Single mother with only MGF" ///
 16"Single mother with both MGM & MGF" ///
 17"Single mother with only Paunt" ///
 18"Single mother with only Puncle" ///
 19"Single mother with only Paunt & Paunt" ///
 20"Single mother with only Maunt"  ///
 21"Single mother with only Muncle" ///
 22"Single mother with both Maunt & Muncle" ///
 23"Single mother with only Paternal horizontally and vertically Kin" ///
 24"Single mother with only Maternal horizontally and vertically Kin" ///
 25"Single mother with complex family composition" ///
 30"Single father" ///
 31"Single father with only PGM" ///
 32"Single father with only PGF" ///
 33"Single father with both PGM & PGF" ///
 34"Single father with only MGM" ///
 35"Single father with only MGF" ///
 36"Single father with both MGM & MGF" ///
 37"Single father with only Paunt" ///
 38"Single father with only Puncle" ///
 39"Single father with only Paunt & Paunt" ///
 40"Single father with only Maunt"  ///
 41"Single father with only Muncle" ///
 42"Single father with both Maunt & Muncle" ///
 43"Single father with only Paternal horizontally and vertically Kin" ///
 44"Single father with only Maternal horizontally and vertically Kin" ///
 45"Single father with complex family composition" ///
 50"Couple" ///
 51"Couple with only PGM" ///
 52"Couple with only PGF" ///
 53"Couple with both PGM & PGF" ///
 54"Couple with only MGM" ///
 55"Couple with only MGF" ///
 56"Couple with both MGM & MGF" ///
 57"Couple with only Paunt" ///
 58"Couple with only Puncle" ///
 59"Couple with only Paunt & Paunt" ///
 60"Couple with only Maunt"  ///
 61"Couple with only Muncle" ///
 62"Couple with both Maunt & Muncle" ///
 63"Couple with only Paternal horizontally and vertically Kin" ///
 64"Couple with only Maternal horizontally and vertically Kin" ///
 65"Couple with complex family composition" ///
 70"No parent" ///
 71"No parent with only PGM" ///
 72"No parent with only PGF" ///
 73"No parent with both PGM & PGF" ///
 74"No parent with only MGM" ///
 75"No parent with only MGF" ///
 76"No parent with both MGM & MGF" ///
 77"No parent with only Paunt" ///
 78"No parent with only Puncle" ///
 79"No parent with only Paunt & Paunt" ///
 80"No parent with only Maunt"  ///
 81"No parent with only Muncle" ///
 82"No parent with both Maunt & Muncle" ///
 83"No parent with only Paternal horizontally and vertically Kin" ///
 84"No parent with only Maternal horizontally and vertically Kin" ///
 85"No parent with complex family composition" ///
 ,modify
 
label val hh_type hh_type

capture drop dup_e
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId  EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

drop if dup_e>1

save final_dataset_analysis_des,replace

*Correction de la base de donnée
use final_dataset_analysis_des,clear


capture drop hhtype_1
recode hh_type (11 14 = 14 ) (12 15 = 15) (13 16 = 16), gen (hhtype_1)
********************************************************************************
                        ** Descriptive analysis
********************************************************************************
 


 
********************************************************************************
                        ** Dynamics analysis
********************************************************************************






********************************************************************************

*Coresident with parents
replace coresidFA = 2 if coresidFA==1

ta coresidFA coresidMO 
capture drop hh_comp
gen hh_comp = coresidFA + coresidMO

ta hh_comp, m 
label define hhcomp 0"none parent" 1"Single parent - mother only" 2"Single parent - father only" ///
             3"Both parents", modify

label val hh_comp hhcomp 

XX


*Description during the period
graph hbar, over(hh_comp, sort(1)) blabel(bar, format(%4.2f)) intensity(25)
save parents.gph

* A la naissance de l'enfant
graph hbar if EventCode==2, over(hh_comp, sort(1)) 
save  parents_childbirth.gph

forval i=1/5{
graph hbar if hdss==`i', over(hh_comp, sort(1)) blabel(bar, format(%4.2f))  name(g`i', replace) intensity(25) nodraw
 graph save hdss_`i',replace
}

graph combine hdss_1.gph hdss_2.gph hdss_3.gph hdss_4.gph hdss_5.gph,  row(3)

graph combine hdss_1.gph hdss_2.gph hdss_3.gph hdss_4.gph hdss_5.gph,  row(3) xcom

local graphs ""
forval i = 1/5 {
  graph hbar if hdss==`i', over(hh_comp, sort(1)) blabel(bar, format(%4.2f))  name(g`i', replace) nodraw intensity(25) 
  local graphs "`graphs' g`i'"
}
graph combine `graphs', row(3) 

*by HDSS
graph hbar (count),  over(hh_comp, ) over (hdss) asyvars stack percent

graph hbar, over (hdss) over(hh_comp, sort(1))  asyvars stack

graph bar,  over(hh_comp, sort(1)) over (hdss) asyvars stack

graph bar if EventCode==2,  over(hh_comp, sort(1)) over (hdss) asyvars stack

graph hbar if EventCode==2,  over(hh_comp, sort(1)) over (hdss) asyvars stack



