
********************************************************************************
*          Mouvement de la population : Split selon les groupes d'âge
********************************************************************************
cd"C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Farafenni"
use  residency_Farafenni.dta, clear



label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
7 "DTH" 8"-6mDTH" 9 "OBE" 10 "DLV" 11"PREGNANT"18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab




drop if  EventCode>9
sort IndividualID EventDate EventCode
bys IndividualID EventDate :replace EventCode=2 if EventCode!=2&EventDate==DoB

**Normalement des immigrations [en lieu et place de déménagements. On rentre 
*pour la première fois dans le HDSS par IMG, ENUM, ou BTH et non par ENT.
capture drop a
bys  IndividualID : gen a=1 if EventCode[1]==6
br IndividualID EventDate EventCode if a==1
bys IndividualID  : replace EventCode=3 if EventCode[1]==6
bys IndividualID  : replace EventCode=4 if EventCode==5 &  Compound==Compound[_n+1]


**Modification 20022019
*Fixer la date de censure au 01 Janvier 2014
sort IndividualID EventDate EventCode
qui by IndividualID: replace datebeg=cond(_n==1, DoB, EventDate[_n-1])

sort EventDate
gen double last_obs = (_n == _N)
gen double last_record_date_1 = EventDate if last_obs==1
format last_record_date_1 %tc
sort last_record_date_1
replace last_record_date_1 = last_record_date_1[_n-1] if missing(last_record_date_1) & _n > 1 




*bys IndividualID (EventDate): replace last_record_date_1 = last_record_date_1[_N]

display %20.0f clock("01Jan 2016","DMY") /* A revoir */
*   1767225600000
*End Date
*gen double last_record_date_1 = clock("01Jan 2014","DMY",2020)
*format last_record_date_1 %tc


*20820
sort IndividualID EventDate EventCode
expand=2 if IndividualID!=IndividualID[_n+1] & EventDate<last_record_date_1, gen(duplicate)
br IndividualID EventDate EventCode if duplicate==1

*158107 observations complétées
  
sort IndividualID EventDate EventCode duplicate
by IndividualID : replace EventDate=last_record_date_1  if duplicate==1
by IndividualID : replace EventCode=9  if duplicate==1

drop duplicate



sort IndividualID EventDate
br IndividualID EventDate EventCode




/*
*Transform all dates in tc format
foreach var of varlist  EventDate DoB{
gen double `var'_1 = cofd(`var')
format `var'_1 %tc
drop `var'
rename `var'_1 `var'
}

*/

sort IndividualID EventDate EventCode
*Petites corrections sur le fichier de résidence
*replace EventDate=DoB if IndividualID=="21C011AE1291H001009"
bysort IndividualID EventDate :replace EventCode=2 if EventDate==DoB&_n==1

*Modification 21022019
sort IndividualID EventDate EventCode
by IndividualID : gen b=1 if EventDate==EventDate[_n-1]



*Add an half day to the exit date
replace EventDate=EventDate + 12*60*60*1000 if b==1
*replace EventDate=EventDate + 12*60*60*1000 if EventCode==2

*Supprimer les doublons
quietly bys IndividualID EventDate EventCode : gen dup_e = cond(_N==1,0,_n)
drop if dup_e>1 


capture drop datebeg
bysort IndividualID : gen  double datebeg=cond(_n==1,DoB,EventDate[_n-1])
*replace EventDate = datebeg if datebeg==EventDate
format datebeg %tc


cap drop lastrecord
qui by IndividualID: gen lastrecord=_n==_N

capture drop datebeg
bysort IndividualID : gen  double datebeg=cond(_n==1,DoB,EventDate[_n-1])
*replace EventDate = datebeg if datebeg==EventDate
format datebeg %tc


stset EventDate , id(IndividualID) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) exit(time .)


	
cap drop censor_death
qui gen censor_death=(EventCode==7) 

	
capture drop group_age
display %20.0f (5*365.25*24*60*60*1000)+212000 /*5ans*/
*157788212000
display %20.0f (10*365.25*24*60*60*1000) /*10 ans*/
*315576000000
display %20.0f (15*365.25*24*60*60*1000) /*15 ans*/
*473364000000
display %20.0f (50*365.25*24*60*60*1000) /*50 ans*/
* 1577880000000
display %20.0f (65*365.25*24*60*60*1000) /*65 ans)*/
*2051244000000

stsplit group_age, at(0 157788212000 315576000000 473364000000 1577880000000 2051244000000) 

*replace group_age=group_age/1000 
sort IndividualID EventDate EventCode
drop lastrecord
*drop _*

recode group_age (0=0 "0-5ans") (157788212000=1 "5-10 yr") (315576000000=2 "10-15 yr") ///
                 (473364000000=3 "15-50 yr") (1577880000000=4 "50-65 yr") ///
				 (2051244000000=5 "65+ yr") (*=.), gen(group_age_bis)
				 
replace group_age_bis=0 if EventCode==2 & group_age_bis==.


sort IndividualID EventDate EventCode
br IndividualID EventDate EventCode

*24feb1983 12:00:00
display %20.0f clock("24 Feb 1983","DMY")
*     730512000000

drop if EventDate<730512000000

*XX
*Date de censure 01 Janvier 2017
display %20.0f clock("01Jan 2016","DMY")

***Correct the line with wrong value of EventCode

 sort  IndividualID EventDate
 forval i=1/9{
 bys  IndividualID : replace EventCode=21 if EventCode==`i' & EventCode[_n+1]==`i' & (group_age!=group_age[_n+1])
}
 
 sort  IndividualID EventDate
 bys  IndividualID : drop  if EventCode==21 & EventCode[_n-1]==4 
 bys  IndividualID : drop if EventCode==21 & EventCode[_n-1]==7
 bys  IndividualID : drop  if EventCode==21 & EventCode[_n-1]==4 
 bys  IndividualID : drop if EventCode==21 & EventCode[_n-1]==7
 
sort  IndividualID EventDate
bys  IndividualID : replace EventCode=. if EventCode==21&_n==1

drop if EventCode==.

sort  IndividualID EventDate
bys  IndividualID : replace EventCode=. if EventCode==21&_n==1
drop if EventCode==.

sort  IndividualID EventDate
bys  IndividualID : replace EventCode=. if EventCode==21&_n==1
drop if EventCode==.




*Transform all dates in td format
foreach var of varlist  EventDate DoB{
gen double `var'_1 = dofc(`var')
format `var'_1 %td
drop `var'
rename `var'_1 `var'
}


*Détecté les individus qui sortent et qui rentrent à la même date [mais ne pas les supprimer pour la cohérence interne]

sort IndividualID EventDate EventCode
br IndividualID EventDate EventCode EventDate EventCode if EventCode==5&EventCode[_n+1]==6 & EventDate !=EventDate[_n+1]
br IndividualID EventDate EventCode EventDate EventCode if EventCode==6&EventCode[_n-1]==5 & EventDate !=EventDate[_n-1]
bys IndividualID :gen doub_bis=(EventCode==6&EventCode[_n-1]==5 & EventDate !=EventDate[_n-1])
bys IndividualID :replace EventDate=EventDate[_n-1] if doub_bis==1
bys IndividualID :gen doub=(EventCode==5 & EventCode[_n+1]==6 & EventDate !=EventDate[_n+1])



gen erreur = doub
replace erreur = doub_bis if erreur==0
*drop if erreur==1


sort IndividualID EventDate EventCode

bys IndividualID : gen entry_error = (EventCode[1]==6)
replace EventCode=3 if entry_error==1

bys IndividualID : gen entry_bth = (EventCode[1]!=2)& EventDate[1]==DoB 
replace EventCode=3 if entry_bth==1


********************************************************************************
*          Mouvement de la population : Taille de la population
********************************************************************************
rename  HouseholdId  socialgpid
*Nombre de personnes énumérées dans le ménage	  

sort socialgpid EventDate EventCode
gen enum=EventCode==1
replace enum=. if enum==0


*Identification des énumération dans le ménage
sort socialgpid enum DoB
quietly by socialgpid enum: gen rg_enum=cond(_N==1,1,_n)
replace rg_enum=. if enum==.

*Récupération de la date d'énumération
gen Enum_date = EventDate if enum==1
sort socialgpid IndividualID enum
bys socialgpid IndividualID: replace Enum_date = Enum_date[_n-1] if missing(Enum_date) & _n > 1 
bys IndividualID: replace Enum_date = Enum_date[_N] if missing(Enum_date)
count if Enum_date==.
format Enum_date %td


*Tout le monde
ta rg_enum
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Enum_date`i'=Enum_date if rg_enum==`i'
format Enum_date`i' %td
qui by socialgpid: egen Enum_datef`i'=min(Enum_date`i')
format Enum_datef`i' %td
}




*Calcul du nombre d'énumération à chaque date

ta rg_enum
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enumt`i'=(EventDate>=Enum_datef`i') if Enum_datef`i'!=.
replace enumt`i'=0 if enumt`i'==.
}


egen total_enum = rowtotal(enumt*)




***Nombre de personnes émigrations dans le ménage	  
sort socialgpid EventDate EventCode
gen out=EventCode==4
replace out=. if out==0

sort socialgpid out DoB
quietly by socialgpid out: gen rg_out=cond(_N==1,1,_n)
replace rg_out=. if out==.


gen Out_date = EventDate if out==1
sort socialgpid IndividualID rg_out
bys socialgpid IndividualID: replace Out_date = Out_date[_n-1] if missing(Out_date) & _n > 1 
bys IndividualID rg_out: replace Out_date = Out_date[_N] if missing(Out_date)
count if Out_date==.
format Out_date %td

ta rg_out
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date`i'=Out_date if rg_out==`i'
format Out_date`i' %td
qui by socialgpid: egen Out_datef`i'=min(Out_date`i')
format Out_datef`i' %td
}



ta rg_out
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen outt`i'=(EventDate>Out_datef`i') if Out_datef`i'!=.
replace outt`i'=0 if outt`i'==.
}

egen total_out = rowtotal(outt*)





***Nombre de personnes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext=EventCode==5
replace ext=. if ext==0

sort socialgpid ext DoB
quietly by socialgpid ext: gen rg_ext=cond(_N==1,1,_n)
replace rg_ext=. if ext==.


gen Ext_date = EventDate if ext==1
sort socialgpid IndividualID rg_ext
bys socialgpid IndividualID : replace Ext_date = Ext_date[_n-1] if missing(Ext_date) & _n > 1 
bys IndividualID rg_ext: replace Ext_date = Ext_date[_N] if missing(Ext_date)
count if Ext_date==.
format Ext_date %td

ta rg_ext
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date`i'=Ext_date if rg_ext==`i'
format Ext_date`i' %td
qui by socialgpid: egen Ext_datef`i'=min(Ext_date`i')
format Ext_datef`i' %td
}



ta rg_ext
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt`i'=(EventDate>Ext_datef`i') if Ext_datef`i'!=.
replace extt`i'=0 if extt`i'==.
}

egen total_ext = rowtotal(extt*)





***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint=(EventCode==6)
replace eint=. if eint==0

sort socialgpid eint DoB
quietly by socialgpid eint: gen rg_int=cond(_N==1,1,_n)
replace rg_int=. if eint==.


gen Int_date = EventDate if eint==1
sort socialgpid IndividualID rg_int
bys socialgpid IndividualID: replace Int_date = Int_date[_n-1] if missing(Int_date) & _n > 1 
bys IndividualID rg_int: replace Int_date = Int_date[_N] if missing(Int_date)
count if Int_date==.
format Int_date %td

ta rg_int
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date`i'=Int_date if rg_int==`i'
format Int_date`i' %td
qui by socialgpid: egen Int_datef`i'=min(Int_date`i')
format Int_datef`i' %td
}



ta rg_int
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt`i'=(EventDate>Int_datef`i') if Int_datef`i'!=.
replace intt`i'=0 if intt`i'==.
}

egen total_intt = rowtotal(intt*)







***Nombre d'immigrations dans le ménage		  
	  
sort socialgpid EventDate EventCode
gen inm=EventCode==3
replace inm=. if inm==0

sort socialgpid inm DoB
quietly by socialgpid inm: gen rg_inm=cond(_N==1,1,_n)
replace rg_inm=. if inm==.

gen Inm_date = EventDate if inm==1
sort socialgpid IndividualID rg_inm
bys socialgpid IndividualID  : replace Inm_date = Inm_date[_n-1] if missing(Inm_date) & _n > 1 
bys socialgpid IndividualID rg_inm : replace Inm_date = Inm_date[_N] if missing(Inm_date)
count if Inm_date==.
format Inm_date %td

ta rg_inm
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui bys socialgpid rg_inm: gen Inm_date`i'=Inm_date if rg_inm==`i'
format Inm_date`i' %td
qui by socialgpid: egen Inm_datef`i'=min(Inm_date`i')
format Inm_datef`i' %td
}



ta rg_inm
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen  inmt`i'=(EventDate>Inm_datef`i') if Inm_datef`i'!=.
replace inmt`i'=0 if inmt`i'==.
}

egen total_inm = rowtotal(inmt*)


***Nombre de naissances dans le ménage		  
	  
sort socialgpid EventDate EventCode
gen bth=EventCode==2
replace bth=. if bth==0

sort socialgpid bth DoB
quietly by socialgpid bth: gen rg_bth=cond(_N==1,1,_n)
replace rg_bth=. if bth==.


gen Bth_date = EventDate if bth==1
sort socialgpid IndividualID rg_bth
bys socialgpid IndividualID: replace Bth_date = Bth_date[_n-1] if missing(Bth_date) & _n > 1 
bys IndividualID rg_bth: replace Bth_date = Bth_date[_N] if  missing(Bth_date)
count if Bth_date==.
format Bth_date %td

ta rg_bth
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Bth_date`i'=Bth_date if rg_bth==`i'
format Bth_date`i' %td
qui by socialgpid: egen Bth_datef`i'=min(Bth_date`i')
format Bth_datef`i' %td
}



ta rg_bth
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen  btht`i'=(EventDate>Bth_datef`i') if Bth_datef`i'!=.
replace btht`i'=0 if btht`i'==.
}

egen total_bth = rowtotal(btht*)


***Nombre de décès dans le ménage		  
 
sort socialgpid EventDate EventCode
gen dth=EventCode==7
replace dth=. if dth==0

sort socialgpid dth DoB
quietly by socialgpid dth: gen rg_dth=cond(_N==1,1,_n)
replace rg_dth=. if dth==.


gen Dth_date = EventDate if dth==1
sort socialgpid IndividualID rg_dth
bys IndividualID rg_dth: replace Dth_date = Dth_date[_n-1] if missing(Dth_date) & _n > 1 
bys socialgpid IndividualID: replace Dth_date = Dth_date[_N] if missing(Dth_date)
count if Dth_date==.
format Dth_date %td

ta rg_dth
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date`i'=Dth_date if rg_dth==`i'
format Dth_date`i' %td
qui by socialgpid: egen Dth_datef`i'=min(Dth_date`i')
format Dth_datef`i' %td
}



ta rg_dth
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen  dtht`i'=(EventDate>Dth_datef`i') if Dth_datef`i'!=.
replace dtht`i'=0 if dtht`i'==.
}

egen total_dth = rowtotal(dtht*)













/*Taille de la population  : nombre de personnes enumérées + nombre de naissances
+ nombre d'immigrations - nombre d'émigrations - nombre de décès*/
gen hh_size = total_enum + total_bth + total_inm + total_intt - total_out - total_dth - total_ext  



********************************************************************************
*  Mouvement des femmes : Nombre de femmes dans le ménage
********************************************************************************
rename Sex gender
*Nombre de femmes énumérées
sort socialgpid EventDate EventCode
gen enum_girl=EventCode==1 & gender==2
replace enum_girl=. if enum_girl==0

sort socialgpid enum_girl DoB
quietly by socialgpid enum_girl: gen rg_enum_girl=cond(_N==1,1,_n) if enum_girl==1
replace rg_enum_girl=. if rg_enum_girl==.


gen Enum_date_girl = EventDate if enum_girl==1
sort socialgpid IndividualID rg_enum_girl
bys socialgpid IndividualID : replace Enum_date_girl = Enum_date_girl[_n-1] if missing(Enum_date_girl) & _n > 1 
bys IndividualID rg_enum_girl : replace Enum_date_girl = Enum_date_girl[_N] if missing(Enum_date_girl)
count if Enum_date_girl==.
format Enum_date_girl %td



ta rg_enum_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Enum_date_girl`i'=Enum_date_girl if rg_enum_girl==`i'
format Enum_date_girl`i' %td
qui by socialgpid: egen Enum_datef_girl`i'=min(Enum_date_girl`i')
format Enum_datef_girl`i' %td
}

ta rg_enum_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enum_girl_t`i'=(EventDate>=Enum_datef_girl`i') if Enum_datef_girl`i'!=.
replace enum_girl_t`i'=0 if enum_girl_t`i'==.
}
egen total_enum_girl = rowtotal(enum_girl_t*)



**Nombre d'émigrations de femmes 	  
sort socialgpid EventDate EventCode
gen out_girl=EventCode==4&gender==2
replace out_girl=. if out_girl==0

sort socialgpid out_girl DoB
quietly by socialgpid out_girl: gen rg_out_girl=cond(_N==1,1,_n)
replace rg_out_girl=. if out_girl==.

gen Out_date_girl = EventDate if out_girl==1
sort socialgpid IndividualID rg_out_girl
bys socialgpid IndividualID : replace Out_date_girl = Out_date_girl[_n-1] if missing(Out_date_girl) & _n > 1 
bys IndividualID rg_out_girl : replace Out_date_girl = Out_date_girl[_N] if missing(Out_date_girl)
count if Out_date_girl==.
format Out_date_girl %td


ta rg_out_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date_girl`i'=Out_date_girl if rg_out_girl==`i'
format Out_date_girl`i' %td
qui by socialgpid: egen Out_datef_girl`i'=min(Out_date_girl`i')
format Out_datef_girl`i' %td
}



ta rg_out_girl
local boucle = `r(r)'
sort socialgpid EventDate

forval i=1/ `boucle'{
gen out_girl_t`i'=(EventDate>Out_datef_girl`i') if Out_datef_girl`i'!=.
replace out_girl_t`i'=0 if out_girl_t`i'==.
}

egen total_out_girl = rowtotal(out_girl_t*)

	  
**Nombre d'immigrations de femmes
sort socialgpid EventDate EventCode
gen inm_girl=EventCode==3&gender==2
replace inm_girl=. if inm_girl==0

sort socialgpid inm_girl DoB
quietly by socialgpid inm_girl: gen rg_inm_girl=cond(_N==1,1,_n)
replace rg_inm_girl=. if inm_girl==.

gen Inm_date_girl = EventDate if inm==1
sort socialgpid IndividualID rg_inm_girl
bys socialgpid IndividualID: replace Inm_date_girl = Inm_date_girl[_n-1] if missing(Inm_date_girl) & _n > 1 
bys IndividualID rg_inm_girl: replace Inm_date_girl = Inm_date_girl[_N] if missing(Inm_date_girl)
count if Inm_date_girl==.
format Inm_date_girl %td


ta rg_inm_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Inm_date_girl`i'=Inm_date_girl if rg_inm_girl==`i'
format Inm_date_girl`i' %td
qui by socialgpid: egen Inm_datef_girl`i'=min(Inm_date_girl`i')
format Inm_datef_girl`i' %td
}


ta rg_inm_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen  inm_girl_t`i'=(EventDate>Inm_datef_girl`i') if Inm_datef_girl`i'!=.
replace inm_girl_t`i'=0 if inm_girl_t`i'==.
}

egen total_inm_girl = rowtotal(inm_girl_t*)


***Nombre de personnes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext_girl=EventCode==5 & gender==2
replace ext_girl=. if ext_girl==0

sort socialgpid ext_girl DoB
quietly by socialgpid ext_girl: gen rg_ext_girl=cond(_N==1,1,_n)
replace rg_ext_girl=. if ext_girl==.


gen Ext_date_girl = EventDate if ext_girl==1
sort socialgpid IndividualID rg_ext_girl
bys socialgpid IndividualID : replace Ext_date_girl = Ext_date_girl[_n-1] if missing(Ext_date_girl) & _n > 1 
bys IndividualID rg_ext_girl: replace Ext_date_girl = Ext_date_girl[_N] if missing(Ext_date_girl)
count if Ext_date_girl==.
format Ext_date_girl %td

ta rg_ext_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date_girl`i'=Ext_date_girl if rg_ext_girl==`i'
format Ext_date_girl`i' %td
qui by socialgpid: egen Ext_datef_girl`i'=min(Ext_date_girl`i')
format Ext_datef_girl`i' %td
}



ta rg_ext_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt_girl`i'=(EventDate>Ext_datef_girl`i') if Ext_datef_girl`i'!=.
replace extt_girl`i'=0 if extt_girl`i'==.
}

egen total_ext_girl = rowtotal(extt_girl*)



***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint_girl=(EventCode==6&gender==2)
replace eint_girl=. if eint_girl==0

sort socialgpid eint_girl DoB
quietly by socialgpid eint_girl: gen rg_int_girl=cond(_N==1,1,_n)
replace rg_int_girl=. if eint_girl==.


gen Int_date_girl = EventDate if eint_girl==1
sort socialgpid IndividualID rg_int_girl
bys socialgpid IndividualID: replace Int_date_girl = Int_date_girl[_n-1] if missing(Int_date_girl) & _n > 1 
bys IndividualID rg_int_girl: replace Int_date_girl = Int_date_girl[_N] if missing(Int_date_girl)
count if Int_date_girl==.
format Int_date_girl %td

ta rg_int_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date_girl`i'=Int_date_girl if rg_int_girl==`i'
format Int_date_girl`i' %td
qui by socialgpid: egen Int_datef_girl`i'=min(Int_date_girl`i')
format Int_datef_girl`i' %td
}



ta rg_int_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt_girl`i'=(EventDate>Int_datef_girl`i') if Int_datef_girl`i'!=.
replace intt_girl`i'=0 if intt_girl`i'==.
}

egen total_intt_girl = rowtotal(intt_girl*)

**Nombre de décès de femmes dans le ménage
sort socialgpid EventDate EventCode
gen dth_girl=EventCode==7 & gender==2
replace dth_girl=. if dth_girl==0

sort socialgpid IndividualID dth_girl

sort socialgpid dth_girl DoB
quietly by socialgpid dth_girl: gen rg_dth_girl=cond(_N==1,1,_n) if dth_girl==1
replace rg_dth_girl=. if rg_dth_girl==.
gen Dth_date_girl = EventDate if dth_girl==1
sort socialgpid IndividualID rg_dth_girl
bys socialgpid IndividualID: replace Dth_date_girl = Dth_date_girl[_n-1] if missing(Dth_date_girl) & _n > 1 
bys IndividualID rg_dth_girl: replace Dth_date_girl = Dth_date_girl[_N] if missing(Dth_date_girl)
count if Dth_date_girl==.
format Dth_date_girl %td

ta rg_dth_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date_girl`i'=Dth_date_girl if rg_dth_girl==`i'
format Dth_date_girl`i' %td
qui by socialgpid: egen Dth_datef_girl`i'=min(Dth_date_girl`i')
format Dth_datef_girl`i' %td
}

ta rg_dth_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen dth_girl_t`i'=(EventDate>Dth_datef_girl`i') if Dth_datef_girl`i'!=.
replace dth_girl_t`i'=0 if dth_girl_t`i'==.
}
egen total_dth_girl = rowtotal(dth_girl_t*)


**Nombre de naissance d'enfants de sexe féminin dans le ménage
sort socialgpid EventDate EventCode
gen bth_girl=EventCode==2 & gender==2
replace bth_girl=. if bth_girl==0

sort socialgpid bth_girl DoB
quietly by socialgpid bth_girl: gen rg_bth_girl=cond(_N==1,1,_n) if bth_girl==1
replace rg_bth_girl=. if rg_bth_girl==.
gen Bth_date_girl = EventDate if bth_girl==1
sort socialgpid IndividualID rg_bth_girl
bys socialgpid IndividualID: replace Bth_date_girl = Bth_date_girl[_n-1] if missing(Bth_date_girl) & _n > 1 
bys IndividualID rg_bth_girl: replace Bth_date_girl = Bth_date_girl[_N] if missing(Bth_date_girl)
count if Bth_date_girl==.
format Bth_date_girl %td

ta rg_bth_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Bth_date_girl`i'=Bth_date_girl if rg_bth_girl==`i'
format Bth_date_girl`i' %td
qui by socialgpid: egen Bth_datef_girl`i'=min(Bth_date_girl`i')
format Bth_datef_girl`i' %td
}

ta rg_bth_girl
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen bth_girl_t`i'=(EventDate>Bth_datef_girl`i') if Bth_datef_girl`i'!=.
replace bth_girl_t`i'=0 if bth_girl_t`i'==.
}
egen total_bth_girl = rowtotal(bth_girl_t*)

gen hh_girl_numb = total_enum_girl + total_inm_girl + total_bth_girl + total_intt_girl ///
- total_out_girl - total_dth_girl - total_ext_girl
				  			  
				 
********************************************************************************
*      Nombre d'hommes dans le ménage
********************************************************************************

* Il suffit de faire la taille du ménage oté du nombre de femmes dans le ménage
gen hh_boys_numb = hh_size - hh_girl_numb

* Suppression des variables intermédiaires
drop rg_* Enum_* enumt* Out_date* outt* Inm_date* inmt* Bth_date* Dth_date* ///
bth btht* dth dtht* enum_girl enum_girl_t* out_girl out_girl_t* inm_girl ///
inm_girl_t* bth_girl bth_girl_t* dup_e


*erreurs dans le fichier
*0
drop if hh_size<0

save base_analyse_hh_1,replace

use base_analyse_hh_1,clear
*Checking incontencies
count if hh_size<0
*0
count if hh_size<hh_girl_numb
* 1,978
count if hh_size<hh_boys_numb
 *2,127
 
*children household was alone in the household [problèmes de dates dans le fichier]
*erreurs terrain
sort socialgpid EventDate
br socialgpid IndividualID EventDate EventCode hh_size group_age_bis ///
 if hh_size==0 & group_age_bis==0 & hh_size[_n+1]==1 & EventDate[_n+1]-EventDate!=0

br socialgpid IndividualID EventDate EventCode hh_size group_age_bis ///
 if hh_size==0 & group_age_bis==1 & hh_size[_n+1]==1 & EventDate[_n+1]-EventDate!=0

br socialgpid IndividualID EventDate EventCode hh_size group_age_bis ///
 if hh_size==0 & group_age_bis==2 & hh_size[_n+1]==1 & EventDate[_n+1]-EventDate!=0

*Children householld
bysort socialgpid: egen children = total(group_age_bis<=2)
bysort socialgpid: gen line_number = _N
br socialgpid IndividualID EventDate EventCode  group_age_bis  if children==line_number

br if children==line_number & line_number==2
br if children==line_number & line_number==3
br if children==line_number & line_number==4



********************************************************************************
* Nombre d'enfants de moins de 5 ans dans le ménage
********************************************************************************
use base_analyse_hh_1,clear
sort IndividualID EventDate EventCode
bys IndividualID EventDate :replace EventCode=2 if EventCode!=2&EventDate==DoB


bys IndividualID EventDate EventCode : gen dup_e = cond(_N==1,0,_n)

drop if dup_e>1 


*Nombre d'enfants énumérés dans le ménage
sort socialgpid EventDate EventCode
gen enum_child=EventCode==1 & group_age_bis==0
replace enum_child=. if enum_child==0

sort socialgpid enum_child DoB
quietly by socialgpid enum_child: gen rg_enum_child=cond(_N==1,1,_n) if enum_child==1
replace rg_enum_child=. if rg_enum_child==.

gen Enum_date_child = EventDate if enum_child==1
sort socialgpid IndividualID rg_enum_child
bys socialgpid IndividualID: replace Enum_date_child = Enum_date_child[_n-1] if missing(Enum_date_child) & _n > 1 
bys  IndividualID rg_enum_child: replace Enum_date_child = Enum_date_child[_N] if  missing(Enum_date_child)
count if Enum_date_child==.
format Enum_date_child %tc

ta rg_enum_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Enum_date_child`i'=Enum_date_child if rg_enum_child==`i'
format Enum_date_child`i' %td
qui by socialgpid: egen double Enum_datef_child`i'=min(Enum_date_child`i')
format Enum_datef_child`i' %td
}

ta rg_enum_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enum_child_t`i'=(EventDate>=Enum_datef_child`i') if Enum_datef_child`i'!=.
replace enum_child_t`i'=0 if enum_child_t`i'==.
}
egen total_enum_child = rowtotal(enum_child_t*)
	  
			  
**Nombre d'émigration d'enfants dans le ménage			  
sort socialgpid EventDate EventCode
gen out_child=EventCode==4 & group_age_bis==0
replace out_child=. if out_child==0

sort socialgpid out DoB
quietly bys socialgpid out_child: gen rg_out_child=cond(_N==1,1,_n)
replace rg_out_child=. if out_child==.
gen Out_date_child = EventDate if out_child==1
sort socialgpid IndividualID rg_out_child
bys  socialgpid IndividualID: replace Out_date_child = Out_date_child[_n-1] if missing(Out_date_child) & _n > 1 
bys IndividualID rg_out_child: replace Out_date_child = Out_date_child[_N] if missing(Out_date_child)
count if Out_date_child==.
format Out_date_child %td

ta rg_out_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date_child`i'=Out_date_child if rg_out_child==`i'
format Out_date_child`i' %td
qui by socialgpid: egen Out_datef_child`i'=min(Out_date_child`i')
format Out_datef_child`i' %td
}



ta rg_out_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen out_child_t`i'=(EventDate>Out_datef_child`i') if Out_datef_child`i'!=.
replace out_child_t`i'=0 if out_child_t`i'==.
}

egen total_out_child = rowtotal(out_child_t*)			  
			  
			  

			  
**Nombre d'immigration d'enfants dans le ménage
sort socialgpid EventDate EventCode
gen inm_child=EventCode==3 & group_age_bis==0
replace inm_child=. if inm_child==0

sort socialgpid inm_child DoB
quietly by socialgpid inm_child: gen rg_inm_child=cond(_N==1,1,_n) if inm_child==1
replace rg_inm_child=. if rg_inm_child==.

gen Inm_date_child = EventDate if inm_child==1

sort socialgpid IndividualID rg_inm_child
bys  socialgpid IndividualID: replace Inm_date_child = Inm_date_child[_n-1] if missing(Inm_date_child) & _n > 1 
bys IndividualID rg_inm_child: replace Inm_date_child = Inm_date_child[_N] if missing(Inm_date_child)
count if Inm_date_child==.
format Inm_date_child %td

ta rg_inm_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Inm_date_child`i'=Inm_date_child if rg_inm_child==`i'
format Inm_date_child`i' %td
qui by socialgpid: egen Inm_datef_child`i'=min(Inm_date_child`i')
format Inm_datef_child`i' %td
}

ta rg_inm_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen inm_child_t`i'=(EventDate>Inm_datef_child`i') if Inm_datef_child`i'!=.
replace inm_child_t`i'=0 if inm_child_t`i'==.
}
egen total_inm_child = rowtotal(inm_child_t*)

			  				  
***Nombre de personnes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext_child=EventCode==5  & group_age_bis==0
replace ext_child=. if ext_child==0

sort socialgpid ext_child DoB
quietly by socialgpid ext_child: gen rg_ext_child =cond(_N==1,1,_n)
replace rg_ext_child=. if ext_child==.


gen Ext_date_child = EventDate if ext_child==1
sort socialgpid IndividualID rg_ext_child
bys socialgpid IndividualID : replace Ext_date_child = Ext_date_child[_n-1] if missing(Ext_date_child) & _n > 1 
bys IndividualID rg_ext_child: replace Ext_date_child = Ext_date_child[_N] if missing(Ext_date_child)
count if Ext_date_child==.
format Ext_date_child %td

ta rg_ext_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date_child`i'=Ext_date_child if rg_ext_child==`i'
format Ext_date_child`i' %td
qui by socialgpid: egen Ext_datef_child`i'=min(Ext_date_child`i')
format Ext_datef_child`i' %td
}



ta rg_ext_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt_child`i'=(EventDate>Ext_datef_child`i') if Ext_datef_child`i'!=.
replace extt_child`i'=0 if extt_child`i'==.
}

egen total_ext_child = rowtotal(extt_child*)



* [Il n'ya pas d'enfants de moins de 5 ans déménagés]

***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint_child=(EventCode==6 & group_age_bis==0)
replace eint_child=. if eint_child==0

sort socialgpid eint_child DoB
quietly by socialgpid eint_child: gen rg_int_child=cond(_N==1,1,_n)
replace rg_int_child=. if eint_child==.


gen Int_date_child = EventDate if eint_child==1
sort socialgpid IndividualID rg_int_child
bys socialgpid IndividualID: replace Int_date_child = Int_date_child[_n-1] if missing(Int_date_child) & _n > 1 
bys IndividualID rg_int_child : replace Int_date_child = Int_date_child[_N] if missing(Int_date_child)
count if Int_date_child==.
format Int_date_child %td

ta rg_int_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date_child`i'=Int_date_child if rg_int_child==`i'
format Int_date_child`i' %td
qui by socialgpid: egen Int_datef_child`i'=min(Int_date_child`i')
format Int_datef_child`i' %td
}



ta rg_int_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt_child`i'=(EventDate>Int_datef_child`i') if Int_datef_child`i'!=.
replace intt_child`i'=0 if intt_child`i'==.
}

egen total_intt_child = rowtotal(intt_child*)
						  
  
							  
**Nombre de décès d'enfants de moins de 5 ans dans le ménage
sort socialgpid EventDate EventCode
gen dth_child=EventCode==7 & group_age_bis==0
replace dth_child=. if dth_child==0

sort socialgpid dth_child DoB
quietly by socialgpid dth_child: gen rg_dth_child=cond(_N==1,1,_n) if dth_child==1
replace rg_dth_child=. if rg_dth_child==.
gen Dth_date_child = EventDate if dth_child==1

sort socialgpid IndividualID rg_dth_child
bys  socialgpid IndividualID: replace Dth_date_child = Dth_date_child[_n-1] if missing(Dth_date_child) & _n > 1 
bys IndividualID rg_dth_child: replace Dth_date_child = Dth_date_child[_N] if missing(Dth_date_child)
count if Dth_date_child==.
format Dth_date_child %td

ta rg_dth_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date_child`i'=Dth_date_child if rg_dth_child==`i'
format Dth_date_child`i' %td
qui by socialgpid: egen Dth_datef_child`i'=min(Dth_date_child`i')
format Dth_datef_child`i' %td
}

ta rg_dth_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen dth_child_t`i'=(EventDate>Dth_datef_child`i') if Dth_datef_child`i'!=.
replace dth_child_t`i'=0 if dth_child_t`i'==.
}
egen total_dth_child = rowtotal(dth_child_t*)


**Nombre de naissance dans le ménage
sort socialgpid EventDate EventCode
gen bth_child=EventCode==2 & group_age_bis==0
replace bth_child=. if bth_child==0

sort socialgpid bth_child DoB
quietly by socialgpid bth_child: gen rg_bth_child=cond(_N==1,1,_n) if bth_child==1
replace rg_bth_child=. if rg_bth_child==.

gen Bth_date_child = EventDate if bth_child==1
sort socialgpid IndividualID rg_bth_child
bys  socialgpid IndividualID: replace Bth_date_child = Bth_date_child[_n-1] if missing(Bth_date_child) & _n > 1 
bys IndividualID rg_bth_child: replace Bth_date_child = Bth_date_child[_N] if missing(Bth_date_child)
count if Bth_date_child==.
format Bth_date_child %td

ta rg_bth_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Bth_date_child`i'=Bth_date_child if rg_bth_child==`i'
format Bth_date_child`i' %td
qui by socialgpid: egen Bth_datef_child`i'=min(Bth_date_child`i')
format Bth_datef_child`i' %td
}

ta rg_bth_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen bth_child_t`i'=(EventDate>Bth_datef_child`i') if Bth_datef_child`i'!=.
replace bth_child_t`i'=0 if bth_child_t`i'==.
}
egen total_bth_child = rowtotal(bth_child_t*)

*Changement de groupe de date d'âge [passage de 0-5 ans à 5-10 ans]
capture drop change
sort IndividualID EventDate EventCode 
bys IndividualID : gen change=group_age_bis==0 & EventCode==21
bys IndividualID : replace change =. if group_age_bis!=0
replace change=. if change!=1
egen no_childr = total(group_age_bis==1), by(socialgpid) 

sort socialgpid change DoB
quietly by socialgpid change: gen rg_change_child=cond(_N==1,1,_n) if change==1
replace rg_change_child=. if rg_change_child==.
gen Change_date_child = EventDate if change==1
sort socialgpid IndividualID rg_change_child

bys socialgpid IndividualID: replace Change_date_child = Change_date_child[_n-1] if missing(Change_date_child) & _n > 1 
bys IndividualID rg_change_child: replace Change_date_child = Change_date_child[_N] if missing(Change_date_child)
count if Change_date_child==.
format Change_date_child %td

ta rg_change_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Change_date_child`i'=Change_date_child if rg_change_child==`i'
format Change_date_child`i' %td
qui by socialgpid: egen double Change_datef_child`i'=min(Change_date_child`i')
format Change_datef_child`i' %td
}

ta rg_change_child
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen change_child_t`i'=(EventDate>Change_datef_child`i') if Change_datef_child`i'!=.
replace change_child_t`i'=0 if change_child_t`i'==.
}
egen total_change_child = rowtotal(change_child_t*)


/*Nombre d'enfants = nombre d'enfants énumérés + nombre d'immigration d'enfants
+ Nombre de naissances - nombre d'émigration d'enfants - Nombre de décès d'enfants
- nombre de changements de groupe d'âge 
*/
gen hh_child_numb = total_enum_child + total_inm_child + total_bth_child + total_intt_child  ///
- total_out_child - total_dth_child - total_change_child - total_ext_child
		
		
				*Correction de certaines lignes
sort socialgpid EventDate
bys socialgpid : replace hh_child_numb = 0 if hh_size==0 & hh_child_numb!=0

save base_analyse_hh_2,replace


********************************************************************************
/* Nombre de d'adolescentes âgés entre 10 et 15 ans [potentiel main d'eouvre dans la 
         prise en charge des enfants */
********************************************************************************
use base_analyse_hh_2,clear
sort IndividualID EventDate EventCode



*Nombre de jeunes filles de 10-15 ans énumérées dans le ménage
sort socialgpid EventDate EventCode
gen enum_ado=EventCode==1 & group_age_bis==2 & gender==2
replace enum_ado=. if enum_ado==0

sort socialgpid enum_ado DoB
quietly by socialgpid enum_ado: gen rg_enum_ado=cond(_N==1,1,_n) if enum_ado==1
replace rg_enum_ado=. if rg_enum_ado==.

gen Enum_date_ado = EventDate if enum_ado==1
sort socialgpid IndividualID rg_enum_ado
bys socialgpid IndividualID : replace Enum_date_ado = Enum_date_ado[_n-1] if missing(Enum_date_ado) & _n > 1 
bys IndividualID rg_enum_ado: replace Enum_date_ado = Enum_date_ado[_N] if missing(Enum_date_ado)
count if Enum_date_ado==.
format Enum_date_ado %td

ta rg_enum_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Enum_date_ado`i'=Enum_date_ado if rg_enum_ado==`i'
format Enum_date_ado`i' %td
qui by socialgpid: egen double Enum_datef_ado`i'=min(Enum_date_ado`i')
format Enum_datef_ado`i' %td
}

ta rg_enum_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enum_ado_t`i'=(EventDate>=Enum_datef_ado`i') if Enum_datef_ado`i'!=.
replace enum_ado_t`i'=0 if enum_ado_t`i'==.
}
egen total_enum_ado = rowtotal(enum_ado_t*)
	  
			  
*Nombre d'émigrations d'adolescentes de 10-15 ans dans le ménage		  
sort socialgpid EventDate EventCode
gen out_ado=EventCode==4 & group_age_bis==2 & gender==2
replace out_ado=. if out_ado==0

sort socialgpid out_ado DoB
quietly bys socialgpid out_ado: gen rg_out_ado=cond(_N==1,1,_n)
replace rg_out_ado=. if out_ado==.

gen Out_date_ado = EventDate if out_ado==1
sort socialgpid IndividualID rg_out_ado
bys socialgpid IndividualID: replace Out_date_ado = Out_date_ado[_n-1] if missing(Out_date_ado) & _n > 1 
bys IndividualID rg_out_ado: replace Out_date_ado = Out_date_ado[_N] if missing(Out_date_ado)
count if Out_date_ado==.
format Out_date_ado %td

ta rg_out_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date_ado`i'=Out_date_ado if rg_out_ado==`i'
format Out_date_ado`i' %td
qui by socialgpid: egen Out_datef_ado`i'=min(Out_date_ado`i')
format Out_datef_ado`i' %td
}



ta rg_out_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen out_ado_t`i'=(EventDate>Out_datef_ado`i') if Out_datef_ado`i'!=.
replace out_ado_t`i'=0 if out_ado_t`i'==.
}

egen total_out_ado = rowtotal(out_ado_t*)			  
			  
			  
			  
  
			  
*Nombre d'immigration d'adolescentes de 10-15 ans dans le ménage
sort socialgpid EventDate EventCode
gen inm_ado=EventCode==3 & group_age_bis==2 & gender==2
replace inm_ado=. if inm_ado==0

sort socialgpid inm_ado DoB
quietly by socialgpid inm_ado: gen rg_inm_ado=cond(_N==1,1,_n) if inm_ado==1
replace rg_inm_ado=. if rg_inm_ado==.
gen Inm_date_ado = EventDate if inm_ado==1
sort socialgpid IndividualID rg_inm_ado
bys socialgpid IndividualID: replace Inm_date_ado = Inm_date_ado[_n-1] if missing(Inm_date_ado) & _n > 1 
bys IndividualID rg_inm_ado: replace Inm_date_ado = Inm_date_ado[_N]   if missing(Inm_date_ado)
count if Inm_date_ado==.
format Inm_date_ado %td

ta rg_inm_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Inm_date_ado`i'=Inm_date_ado if rg_inm_ado==`i'
format Inm_date_ado`i' %td
qui by socialgpid: egen Inm_datef_ado`i'=min(Inm_date_ado`i')
format Inm_datef_ado`i' %td
}

ta rg_inm_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen inm_ado_t`i'=(EventDate>Inm_datef_ado`i') if Inm_datef_ado`i'!=.
replace inm_ado_t`i'=0 if inm_ado_t`i'==.
}
egen total_inm_ado = rowtotal(inm_ado_t*)



***Nombre de d'adolescentes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext_ado=EventCode==5 & group_age_bis==2 & gender==2
replace ext_ado=. if ext_ado==0

sort socialgpid ext_ado DoB
quietly bys socialgpid ext_ado: gen rg_ext_ado =cond(_N==1,1,_n)
replace rg_ext_ado=. if ext_ado==.


gen Ext_date_ado = EventDate if ext_ado==1
sort socialgpid IndividualID rg_ext_ado
bys socialgpid IndividualID : replace Ext_date_ado = Ext_date_ado[_n-1] if missing(Ext_date_ado) & _n > 1 
bys IndividualID rg_ext_ado: replace Ext_date_ado = Ext_date_ado[_N] if missing(Ext_date_ado)
count if Ext_date_ado==.
format Ext_date_ado %td

ta rg_ext_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date_ado`i'=Ext_date_ado if rg_ext_ado==`i'
format Ext_date_ado`i' %td
qui by socialgpid: egen Ext_datef_ado`i'=min(Ext_date_ado`i')
format Ext_datef_ado`i' %td
}



ta rg_ext_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt_ado`i'=(EventDate>Ext_datef_ado`i') if Ext_datef_ado`i'!=.
replace extt_ado`i'=0 if extt_ado`i'==.
}

egen total_ext_ado = rowtotal(extt_ado*)



* [Il n'ya pas d'enfants de moins de 5 ans déménagés]

***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint_ado=(EventCode==6 & group_age_bis==2 & gender==2)
replace eint_ado=. if eint_ado==0

sort socialgpid eint_ado DoB
quietly bys socialgpid eint_ado: gen rg_int_ado=cond(_N==1,1,_n)
replace rg_int_ado=. if eint_ado==.


gen Int_date_ado = EventDate if eint_ado==1
sort socialgpid IndividualID rg_int_ado
bys socialgpid IndividualID: replace Int_date_ado = Int_date_ado[_n-1] if missing(Int_date_ado) & _n > 1 
bys IndividualID rg_int_ado : replace Int_date_ado = Int_date_ado[_N] if missing(Int_date_ado)
count if Int_date_ado==.
format Int_date_ado %td

ta rg_int_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date_ado`i'=Int_date_ado if rg_int_ado==`i'
format Int_date_ado`i' %td
qui by socialgpid: egen Int_datef_ado`i'=min(Int_date_ado`i')
format Int_datef_ado`i' %td
}



ta rg_int_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt_ado`i'=(EventDate>Int_datef_ado`i') if Int_datef_ado`i'!=.
replace intt_ado`i'=0 if intt_ado`i'==.
}

egen total_intt_ado = rowtotal(intt_ado*)
						  

			  				  

* Nombre de décès d'adolescentes de 10-15 ans dans le ménage
sort socialgpid EventDate EventCode
gen dth_ado=EventCode==7 & group_age_bis==2 & gender==2
replace dth_ado=. if dth_ado==0

sort socialgpid dth_ado DoB
quietly bys socialgpid dth_ado: gen rg_dth_ado=cond(_N==1,1,_n) if dth_ado==1
replace rg_dth_ado=. if rg_dth_ado==.

gen Dth_date_ado = EventDate if dth_ado==1
sort socialgpid IndividualID rg_dth_ado
bys socialgpid IndividualID: replace Dth_date_ado = Dth_date_ado[_n-1] if missing(Dth_date_ado) & _n > 1 
bys IndividualID rg_dth_ado: replace Dth_date_ado = Dth_date_ado[_N] if missing(Dth_date_ado)
count if Dth_date_ado==.
format Dth_date_ado %td

ta rg_dth_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date_ado`i'=Dth_date_ado if rg_dth_ado==`i'
format Dth_date_ado`i' %td
qui by socialgpid: egen Dth_datef_ado`i'=min(Dth_date_ado`i')
format Dth_datef_ado`i' %td
}

ta rg_dth_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen dth_ado_t`i'=(EventDate>Dth_datef_ado`i') if Dth_datef_ado`i'!=.
replace dth_ado_t`i'=0 if dth_ado_t`i'==.
}
egen total_dth_ado = rowtotal(dth_ado_t*)


*Changement de groupe de date de naissance [passage de 10-15 ans à 15 - 50 ans]
capture drop change
sort IndividualID EventDate EventCode 
bys IndividualID : gen change=group_age_bis==2 & EventCode==21 & gender==2
*bys IndividualID : replace change =. if _n==1
bys IndividualID : replace change =. if group_age_bis!=2
replace change=. if change!=1
egen no_ador = total(group_age_bis==2), by(socialgpid) 

sort socialgpid change DoB
quietly by socialgpid change: gen rg_change_ado=cond(_N==1,1,_n) if change==1
replace rg_change_ado=. if rg_change_ado==.

gen Change_date_ado = EventDate if change==1
sort socialgpid IndividualID rg_change_ado
bys socialgpid IndividualID: replace Change_date_ado = Change_date_ado[_n-1] if missing(Change_date_ado) & _n > 1 
bys IndividualID rg_change_ado: replace Change_date_ado = Change_date_ado[_N] if missing(Change_date_ado)
count if Change_date_ado==.
format Change_date_ado %td

ta rg_change_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Change_date_ado`i'=Change_date_ado if rg_change_ado==`i'
format Change_date_ado`i' %td
qui by socialgpid: egen double Change_datef_ado`i'=min(Change_date_ado`i')
format Change_datef_ado`i' %td
}

ta rg_change_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen change_ado_t`i'=(EventDate>Change_datef_ado`i') if Change_datef_ado`i'!=.
replace change_ado_t`i'=0 if change_ado_t`i'==.
}
egen total_change_ado = rowtotal(change_ado_t*)


**

**Changement de groupe de date de naissance [passage de 5-10 ans à 10 - 15 ans]
capture drop change_add
sort IndividualID EventDate EventCode 
bys IndividualID : gen change_add=group_age_bis==1 & EventCode==21 & gender==2
*bys IndividualID : replace change =. if _n==1
bys IndividualID : replace change_add =. if group_age_bis!=1
replace change_add=. if change_add!=1
egen no_ador_add = total(group_age_bis==1), by(socialgpid) 

sort socialgpid change_add DoB
quietly by socialgpid change_add: gen rg_change_add_ado=cond(_N==1,1,_n) if change_add==1
replace rg_change_add_ado=. if rg_change_add_ado==.

gen Change_add_date_ado = EventDate if change_add==1
sort socialgpid IndividualID rg_change_add_ado
bys socialgpid IndividualID: replace Change_add_date_ado = Change_add_date_ado[_n-1] if missing(Change_add_date_ado) & _n > 1 
bys IndividualID rg_change_add_ado: replace Change_add_date_ado = Change_add_date_ado[_N] if missing(Change_add_date_ado)
count if Change_add_date_ado==.
format Change_add_date_ado %td

ta rg_change_add_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Change_add_date_ado`i'=Change_add_date_ado if rg_change_add_ado==`i'
format Change_add_date_ado`i' %td
qui by socialgpid: egen double Change_add_datef_ado`i'=min(Change_add_date_ado`i')
format Change_add_datef_ado`i' %td
}

ta rg_change_add_ado
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen change_add_ado_t`i'=(EventDate>Change_add_datef_ado`i') if Change_add_datef_ado`i'!=.
replace change_add_ado_t`i'=0 if change_add_ado_t`i'==.
}
egen total_change_add_ado = rowtotal(change_add_ado_t*)




/* Nombre d'adolescentes de 10 - 15 ans = Nombre d'adolescentes énumérées + Nombre
d'immigration d'adolescentes + Nombre d'entrées dans le groupe d'âge - Nombre
d'émigration d'adolescentes - Nombre de décès d'adolescentes - Nombre de sorte
dans le groupe d'âge*/
gen hh_ado_numb = total_enum_ado + total_inm_ado  +  total_change_add_ado + total_intt_ado ///
- total_out_ado - total_dth_ado - total_change_ado - total_ext_ado 

*Correction de quelques lignes [erreurs dans les données]
replace hh_ado_numb=0 if hh_size==0
*0
replace hh_ado_numb=0 if hh_ado_numb<0
*0

save base_analyse_hh_3,replace



********************************************************************************
/*Nombre de de femmes âgées de 50 ans et plus (en fin de vie féconde)
       [Potentiel aide dans la prise en charge des enfants]*/
********************************************************************************
use base_analyse_hh_3,clear
sort IndividualID EventDate EventCode



*Nombre de femmes en fin de vie féconde énumérées
sort socialgpid EventDate EventCode
gen enum_gmother=EventCode==1 & group_age_bis>3 & gender==2
replace enum_gmother=. if enum_gmother==0

sort socialgpid enum_gmother DoB
quietly by socialgpid enum_gmother: gen rg_enum_gmother=cond(_N==1,1,_n) if enum_gmother==1
replace rg_enum_gmother=. if rg_enum_gmother==.
gen Enum_date_gmother = EventDate if enum_gmother==1

sort socialgpid IndividualID rg_enum_gmother
bys socialgpid IndividualID: replace Enum_date_gmother = Enum_date_gmother[_n-1] if missing(Enum_date_gmother) & _n > 1 
bys IndividualID enum_gmother: replace Enum_date_gmother = Enum_date_gmother[_N]
count if Enum_date_gmother==.
format Enum_date_gmother %td

ta rg_enum_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Enum_date_gmother`i'=Enum_date_gmother if rg_enum_gmother==`i'
format Enum_date_gmother`i' %td
qui by socialgpid: egen double Enum_datef_gmother`i'=min(Enum_date_gmother`i')
format Enum_datef_gmother`i' %td
}

ta rg_enum_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enum_gmother_t`i'=(EventDate>=Enum_datef_gmother`i') if Enum_datef_gmother`i'!=.
replace enum_gmother_t`i'=0 if enum_gmother_t`i'==.
}
egen total_enum_gmother = rowtotal(enum_gmother_t*)
	  
			  
*Nombre d'émigrations de femmes en fin de vie féconde		  
sort socialgpid EventDate EventCode
gen out_gmother=EventCode==4 & group_age_bis>3 & gender==2
replace out_gmother=. if out_gmother==0

sort socialgpid out_gmother DoB
quietly bys socialgpid out_gmother: gen rg_out_gmother=cond(_N==1,1,_n)
replace rg_out_gmother=. if out_gmother==.

gen Out_date_gmother = EventDate if out_gmother==1
sort socialgpid IndividualID rg_out_gmother
bys socialgpid IndividualID: replace Out_date_gmother = Out_date_gmother[_n-1] if missing(Out_date_gmother) & _n > 1 
bys IndividualID rg_out_gmother: replace Out_date_gmother = Out_date_gmother[_N] if missing(Out_date_gmother)
count if Out_date_gmother==.
format Out_date_gmother %td

ta rg_out_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date_gmother`i'=Out_date_gmother if rg_out_gmother==`i'
format Out_date_gmother`i' %td
qui by socialgpid: egen Out_datef_gmother`i'=min(Out_date_gmother`i')
format Out_datef_gmother`i' %td
}



ta rg_out_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen out_gmother_t`i'=(EventDate>Out_datef_gmother`i') if Out_datef_gmother`i'!=.
replace out_gmother_t`i'=0 if out_gmother_t`i'==.
}

egen total_out_gmother = rowtotal(out_gmother_t*)			  
			  
			  
			  
  
			  
**Nombre d'immigrations de femmes en fin de vie féconde
sort socialgpid EventDate EventCode
gen inm_gmother=EventCode==3 & group_age_bis>3 & gender==2
replace inm_gmother=. if inm_gmother==0

sort socialgpid inm_gmother DoB
quietly by socialgpid inm_gmother: gen rg_inm_gmother=cond(_N==1,1,_n) if inm_gmother==1
replace rg_inm_gmother=. if rg_inm_gmother==.

gen Inm_date_gmother = EventDate if inm_gmother==1
sort socialgpid IndividualID rg_inm_gmother
bys socialgpid IndividualID: replace Inm_date_gmother = Inm_date_gmother[_n-1] if missing(Inm_date_gmother) & _n > 1 
bys IndividualID rg_inm_gmother: replace Inm_date_gmother = Inm_date_gmother[_N] if missing(Inm_date_gmother)
count if Inm_date_gmother==.
format Inm_date_gmother %td

ta rg_inm_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Inm_date_gmother`i'=Inm_date_gmother if rg_inm_gmother==`i'
format Inm_date_gmother`i' %td
qui by socialgpid: egen Inm_datef_gmother`i'=min(Inm_date_gmother`i')
format Inm_datef_gmother`i' %td
}

ta rg_inm_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen inm_gmother_t`i'=(EventDate>Inm_datef_gmother`i') if Inm_datef_gmother`i'!=.
replace inm_gmother_t`i'=0 if inm_gmother_t`i'==.
}
egen total_inm_gmother = rowtotal(inm_gmother_t*)

			 
			 		 

***Nombre de d'adolescentes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext_gmother =EventCode==5 & group_age_bis>3 & gender==2
replace ext_gmother=. if ext_gmother==0

sort socialgpid ext_gmother DoB
quietly bys socialgpid ext_gmother: gen rg_ext_gmother =cond(_N==1,1,_n)
replace rg_ext_gmother=. if ext_gmother==.


gen Ext_date_gmother = EventDate if ext_gmother==1
sort socialgpid IndividualID rg_ext_gmother
bys socialgpid IndividualID : replace Ext_date_gmother = Ext_date_gmother[_n-1] if missing(Ext_date_gmother) & _n > 1 
bys IndividualID rg_ext_gmother: replace Ext_date_gmother = Ext_date_gmother[_N] if missing(Ext_date_gmother)
count if Ext_date_gmother==.
format Ext_date_gmother %td

ta rg_ext_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date_gmother`i'=Ext_date_gmother if rg_ext_gmother==`i'
format Ext_date_gmother`i' %td
qui by socialgpid: egen Ext_datef_gmother`i'=min(Ext_date_gmother`i')
format Ext_datef_gmother`i' %td
}



ta rg_ext_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt_gmother`i'=(EventDate>Ext_datef_gmother`i') if Ext_datef_gmother`i'!=.
replace extt_gmother`i'=0 if extt_gmother`i'==.
}

egen total_ext_gmother = rowtotal(extt_gmother*)



* [Il n'ya pas d'enfants de moins de 5 ans déménagés]

***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint_gmother=(EventCode==6 & group_age_bis>3 & gender==2)
replace eint_gmother=. if eint_gmother==0

sort socialgpid eint_gmother DoB
quietly bys socialgpid eint_gmother: gen rg_int_gmother=cond(_N==1,1,_n)
replace rg_int_gmother=. if eint_gmother==.


gen Int_date_gmother = EventDate if eint_gmother==1
sort socialgpid IndividualID rg_int_gmother
bys socialgpid IndividualID: replace Int_date_gmother = Int_date_gmother[_n-1] if missing(Int_date_gmother) & _n > 1 
bys IndividualID rg_int_gmother : replace Int_date_gmother = Int_date_gmother[_N] if missing(Int_date_gmother)
count if Int_date_gmother==.
format Int_date_gmother %td

ta rg_int_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date_gmother`i'=Int_date_gmother if rg_int_gmother==`i'
format Int_date_gmother`i' %td
qui by socialgpid: egen Int_datef_gmother`i'=min(Int_date_gmother`i')
format Int_datef_gmother`i' %td
}


ta rg_int_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt_gmother`i'=(EventDate>Int_datef_gmother`i') if Int_datef_gmother`i'!=.
replace intt_gmother`i'=0 if intt_gmother`i'==.
}

egen total_intt_gmother = rowtotal(intt_gmother*)
						  

			 			 

*Nombre de décès de femmes en fin de vie féconde
sort socialgpid EventDate EventCode
gen dth_gmother=EventCode==7 & group_age_bis>3 & gender==2
replace dth_gmother=. if dth_gmother==0

sort socialgpid dth_gmother DoB
quietly by socialgpid dth_gmother: gen rg_dth_gmother=cond(_N==1,1,_n) if dth_gmother==1
replace rg_dth_gmother=. if rg_dth_gmother==.
gen Dth_date_gmother = EventDate if dth_gmother==1

sort socialgpid IndividualID rg_dth_gmother
bys socialgpid IndividualID : replace Dth_date_gmother = Dth_date_gmother[_n-1] if missing(Dth_date_gmother) & _n > 1 
bys IndividualID: replace Dth_date_gmother = Dth_date_gmother[_N] if missing(Dth_date_gmother)
count if Dth_date_gmother==.
format Dth_date_gmother %td

ta rg_dth_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date_gmother`i'=Dth_date_gmother if rg_dth_gmother==`i'
format Dth_date_gmother`i' %td
qui by socialgpid: egen Dth_datef_gmother`i'=min(Dth_date_gmother`i')
format Dth_datef_gmother`i' %td
}

ta rg_dth_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen dth_gmother_t`i'=(EventDate>Dth_datef_gmother`i') if Dth_datef_gmother`i'!=.
replace dth_gmother_t`i'=0 if dth_gmother_t`i'==.
}
egen total_dth_gmother = rowtotal(dth_gmother_t*)



*Changement de groupe d'âge [entrée dans la tranche d'âge 50 ans et plus]
capture drop change_add
sort IndividualID EventDate EventCode 
bys IndividualID : gen change_add=group_age_bis==3 & EventCode==21 & gender==2
*bys IndividualID : replace change =. if _n==1
bys IndividualID : replace change_add =. if group_age_bis!=3
replace change_add=. if change_add!=1
egen no_gmotherr_add = total(group_age_bis>3), by(socialgpid) 

sort socialgpid change_add DoB
quietly by socialgpid change_add: gen rg_change_add_gmother=cond(_N==1,1,_n) if change_add==1
replace rg_change_add_gmother=. if rg_change_add_gmother==.

gen Change_add_date_gmother = EventDate if change_add==1

sort socialgpid IndividualID rg_change_add_gmother
bys socialgpid IndividualID : replace Change_add_date_gmother = Change_add_date_gmother[_n-1] if missing(Change_add_date_gmother) & _n > 1 
bys IndividualID rg_change_add_gmother: replace Change_add_date_gmother = Change_add_date_gmother[_N] if missing(Change_add_date_gmother)
count if Change_add_date_gmother==.
format Change_add_date_gmother %td

ta rg_change_add_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Change_add_date_gmother`i'=Change_add_date_gmother if rg_change_add_gmother==`i'
format Change_add_date_gmother`i' %td
qui by socialgpid: egen double Change_add_datef_gmother`i'=min(Change_add_date_gmother`i')
format Change_add_datef_gmother`i' %td
}

ta rg_change_add_gmother
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen change_add_gmother_t`i'=(EventDate>Change_add_datef_gmother`i') if Change_add_datef_gmother`i'!=.
replace change_add_gmother_t`i'=0 if change_add_gmother_t`i'==.
}
egen total_change_add_gmother = rowtotal(change_add_gmother_t*)

/* Nombre de femmes en fin de vie féconde = Nombre de femmes en fin de vie féconde
énumérées + Nombre d'immigrations de femmes en fin de vie féconde + nombre d'entrées
dans le groupe d'âge [50 ans et plus] - nombre d'émigrations de femmes en fin de vie
féconde - Nombre de décès de femmes en fin de vie féconde*/
gen hh_gmother_numb = total_enum_gmother + total_inm_gmother +  total_change_add_gmother + total_intt_gmother  ///
- total_out_gmother - total_dth_gmother - total_ext_gmother 

*Correction de quelques lignes
replace hh_gmother_numb=0 if hh_size==0
*0
replace hh_gmother_numb=0 if hh_gmother_numb<0
*0

save base_analyse_hh_4,replace


********************************************************************************
*                      Nombre d'hommes de 50 ans et plus dans le ménage      ? **
********************************************************************************
use base_analyse_hh_4,clear
sort IndividualID EventDate EventCode



*Nombre d'hommes de 50 ans et plus énumérées
sort socialgpid EventDate EventCode
gen enum_gfather=EventCode==1 & group_age_bis>3 & gender==1
replace enum_gfather=. if enum_gfather==0

sort socialgpid enum_gfather DoB
quietly by socialgpid enum_gfather: gen rg_enum_gfather=cond(_N==1,1,_n) if enum_gfather==1
replace rg_enum_gfather=. if rg_enum_gfather==.
gen Enum_date_gfather = EventDate if enum_gfather==1
sort socialgpid IndividualID rg_enum_gfather

bys socialgpid IndividualID : replace Enum_date_gfather = Enum_date_gfather[_n-1] if missing(Enum_date_gfather) & _n > 1 
bys IndividualID rg_enum_gfather: replace Enum_date_gfather = Enum_date_gfather[_N] if missing(Enum_date_gfather)
count if Enum_date_gfather==.
format Enum_date_gfather %td

ta rg_enum_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Enum_date_gfather`i'=Enum_date_gfather if rg_enum_gfather==`i'
format Enum_date_gfather`i' %td
qui by socialgpid: egen double Enum_datef_gfather`i'=min(Enum_date_gfather`i')
format Enum_datef_gfather`i' %td
}

ta rg_enum_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen enum_gfather_t`i'=(EventDate>=Enum_datef_gfather`i') if Enum_datef_gfather`i'!=.
replace enum_gfather_t`i'=0 if enum_gfather_t`i'==.
}
egen total_enum_gfather = rowtotal(enum_gfather_t*)
	  
			  
**Outmigration			  
sort socialgpid EventDate EventCode
gen out_gfather=EventCode==4 & group_age_bis>3 & gender==1
replace out_gfather=. if out_gfather==0

sort socialgpid out_gfather DoB
quietly bys socialgpid out_gfather: gen rg_out_gfather=cond(_N==1,1,_n)
replace rg_out_gfather=. if out_gfather==.
/*
duplicates tag socialgpid birth,gen(dup)
replace dup=. if birth==.
gen rg_child=dup+1
*/
gen Out_date_gfather = EventDate if out_gfather==1
sort socialgpid IndividualID rg_out_gfather

bys socialgpid IndividualID : replace Out_date_gfather = Out_date_gfather[_n-1] if missing(Out_date_gfather) & _n > 1 
bys IndividualID rg_out_gfather: replace Out_date_gfather = Out_date_gfather[_N] if missing(Out_date_gfather)
count if Out_date_gfather==.
format Out_date_gfather %td

ta rg_out_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Out_date_gfather`i'=Out_date_gfather if rg_out_gfather==`i'
format Out_date_gfather`i' %td
qui by socialgpid: egen Out_datef_gfather`i'=min(Out_date_gfather`i')
format Out_datef_gfather`i' %td
}



ta rg_out_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen out_gfather_t`i'=(EventDate>Out_datef_gfather`i') if Out_datef_gfather`i'!=.
replace out_gfather_t`i'=0 if out_gfather_t`i'==.
}

egen total_out_gfather = rowtotal(out_gfather_t*)			  
			  
			 
			  
**Inmigration
sort socialgpid EventDate EventCode
gen inm_gfather=EventCode==3 & group_age_bis>3 & gender==1
replace inm_gfather=. if inm_gfather==0

sort socialgpid inm_gfather DoB
quietly by socialgpid inm_gfather: gen rg_inm_gfather=cond(_N==1,1,_n) if inm_gfather==1
replace rg_inm_gfather=. if rg_inm_gfather==.
gen Inm_date_gfather = EventDate if inm_gfather==1
sort socialgpid IndividualID rg_inm_gfather

bys socialgpid IndividualID : replace Inm_date_gfather = Inm_date_gfather[_n-1] if missing(Inm_date_gfather) & _n > 1 
bys IndividualID rg_inm_gfather: replace Inm_date_gfather = Inm_date_gfather[_N]  if missing(Inm_date_gfather)
count if Inm_date_gfather==.
format Inm_date_gfather %td

ta rg_inm_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Inm_date_gfather`i'=Inm_date_gfather if rg_inm_gfather==`i'
format Inm_date_gfather`i' %td
qui by socialgpid: egen Inm_datef_gfather`i'=min(Inm_date_gfather`i')
format Inm_datef_gfather`i' %td
}

ta rg_inm_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen inm_gfather_t`i'=(EventDate>Inm_datef_gfather`i') if Inm_datef_gfather`i'!=.
replace inm_gfather_t`i'=0 if inm_gfather_t`i'==.
}
egen total_inm_gfather = rowtotal(inm_gfather_t*)


***Nombre de d'adolescentes déménagées hors du ménage
		  
sort socialgpid EventDate EventCode
gen ext_gfather =EventCode==5 & group_age_bis>3 & gender==1
replace ext_gfather=. if ext_gfather==0

sort socialgpid ext_gfather DoB
quietly bys socialgpid ext_gfather: gen rg_ext_gfather =cond(_N==1,1,_n)
replace rg_ext_gfather=. if ext_gfather==.


gen Ext_date_gfather = EventDate if ext_gfather==1
sort socialgpid IndividualID rg_ext_gfather
bys socialgpid IndividualID : replace Ext_date_gfather = Ext_date_gfather[_n-1] if missing(Ext_date_gfather) & _n > 1 
bys IndividualID rg_ext_gfather: replace Ext_date_gfather = Ext_date_gfather[_N] if missing(Ext_date_gfather)
count if Ext_date_gfather==.
format Ext_date_gfather %td

ta rg_ext_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Ext_date_gfather`i'=Ext_date_gfather if rg_ext_gfather==`i'
format Ext_date_gfather`i' %td
qui by socialgpid: egen Ext_datef_gfather`i'=min(Ext_date_gfather`i')
format Ext_datef_gfather`i' %td
}



ta rg_ext_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen extt_gfather`i'=(EventDate>Ext_datef_gfather`i') if Ext_datef_gfather`i'!=.
replace extt_gfather`i'=0 if extt_gfather`i'==.
}

egen total_ext_gfather = rowtotal(extt_gfather*)


* [Il n'ya pas d'enfants de moins de 5 ans déménagés]

***Nombre de personnes déménagées dans le ménage
		  
sort socialgpid EventDate EventCode
gen eint_gfather=(EventCode==6 & group_age_bis>3 & gender==1)
replace eint_gfather=. if eint_gfather==0

sort socialgpid eint_gfather DoB
quietly bys socialgpid eint_gfather: gen rg_int_gfather=cond(_N==1,1,_n)
replace rg_int_gfather=. if eint_gfather==.


gen Int_date_gfather = EventDate if eint_gfather==1
sort socialgpid IndividualID rg_int_gfather
bys socialgpid IndividualID: replace Int_date_gfather = Int_date_gfather[_n-1] if missing(Int_date_gfather) & _n > 1 
bys IndividualID rg_int_gfather : replace Int_date_gfather = Int_date_gfather[_N] if missing(Int_date_gfather)
count if Int_date_gfather==.
format Int_date_gfather %td

ta rg_int_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Int_date_gfather`i'=Int_date_gfather if rg_int_gfather==`i'
format Int_date_gfather`i' %td
qui by socialgpid: egen Int_datef_gfather`i'=min(Int_date_gfather`i')
format Int_datef_gfather`i' %td
}


ta rg_int_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen intt_gfather`i'=(EventDate>Int_datef_gfather`i') if Int_datef_gfather`i'!=.
replace intt_gfather`i'=0 if intt_gfather`i'==.
}

egen total_intt_gfather = rowtotal(intt_gfather*)
						  

	  				  

**Death
sort socialgpid EventDate EventCode
gen dth_gfather=EventCode==7 & group_age_bis>3 & gender==1
replace dth_gfather=. if dth_gfather==0

sort socialgpid dth_gfather DoB
quietly by socialgpid dth_gfather: gen rg_dth_gfather=cond(_N==1,1,_n) if dth_gfather==1
replace rg_dth_gfather=. if rg_dth_gfather==.
gen Dth_date_gfather = EventDate if dth_gfather==1
sort socialgpid IndividualID rg_dth_gfather
bys socialgpid IndividualID: replace Dth_date_gfather = Dth_date_gfather[_n-1] if missing(Dth_date_gfather) & _n > 1 
bys IndividualID rg_dth_gfather: replace Dth_date_gfather = Dth_date_gfather[_N] if missing(Dth_date_gfather)
count if Dth_date_gfather==.
format Dth_date_gfather %td

ta rg_dth_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen Dth_date_gfather`i'=Dth_date_gfather if rg_dth_gfather==`i'
format Dth_date_gfather`i' %td
qui by socialgpid: egen Dth_datef_gfather`i'=min(Dth_date_gfather`i')
format Dth_datef_gfather`i' %td
}

ta rg_dth_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen dth_gfather_t`i'=(EventDate>Dth_datef_gfather`i') if Dth_datef_gfather`i'!=.
replace dth_gfather_t`i'=0 if dth_gfather_t`i'==.
}
egen total_dth_gfather = rowtotal(dth_gfather_t*)


**

*Changement de groupe d'âge
capture drop change_add
sort IndividualID EventDate EventCode 
bys IndividualID : gen change_add=group_age_bis==3 & EventCode==21 & gender==1
*bys IndividualID : replace change =. if _n==1
bys IndividualID : replace change_add =. if group_age_bis!=3
replace change_add=. if change_add!=1
egen no_gfatherr_add = total(group_age_bis>3), by(socialgpid) 

sort socialgpid change_add DoB
quietly by socialgpid change_add: gen rg_change_add_gfather=cond(_N==1,1,_n) if change_add==1
replace rg_change_add_gfather=. if rg_change_add_gfather==.
gen Change_add_date_gfather = EventDate if change_add==1

sort socialgpid IndividualID rg_change_add_gfather
bys socialgpid IndividualID: replace Change_add_date_gfather = Change_add_date_gfather[_n-1] if missing(Change_add_date_gfather) & _n > 1 
bys IndividualID rg_change_add_gfather: replace Change_add_date_gfather = Change_add_date_gfather[_N] if missing(Change_add_date_gfather)
count if Change_add_date_gfather==.
format Change_add_date_gfather %td

ta rg_change_add_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
qui by socialgpid: gen double Change_add_date_gfather`i'=Change_add_date_gfather if rg_change_add_gfather==`i'
format Change_add_date_gfather`i' %td
qui by socialgpid: egen double Change_add_datef_gfather`i'=min(Change_add_date_gfather`i')
format Change_add_datef_gfather`i' %td
}

ta rg_change_add_gfather
local boucle = `r(r)'
sort socialgpid EventDate
forval i=1/ `boucle'{
gen change_add_gfather_t`i'=(EventDate>Change_add_datef_gfather`i') if Change_add_datef_gfather`i'!=.
replace change_add_gfather_t`i'=0 if change_add_gfather_t`i'==.
}
egen total_change_add_gfather = rowtotal(change_add_gfather_t*)


gen hh_gfather_numb = total_enum_gfather + total_inm_gfather +  total_change_add_gfather + total_intt_gfather   ///
- total_out_gfather - total_dth_gfather - total_ext_gfather

drop  total_* Ext* extt* eint* ext* Int_* int* Enum* enum* rg* ///
inm* Inm* chan* Change* bth* Bth* Dth* dth* out* Out* a ///
doub doub_bis erreur entry_bth entry_error Child* OrderBirth ///
Multiple fatherid last_record_date_1 calendar group_age no_*


save base_analyse_final_Niakhar,replace
