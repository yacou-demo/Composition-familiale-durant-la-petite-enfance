use resid_complet.dta, clear

ta EventCode
*Suppresion des événements dont je n'ai pas besoin
sort IndividualId EventDate EventCode
ta EventCode
ta EventCode,nol
drop if EventCode== 7 | EventCode== 8 |  EventCode== 12 | EventCode==26 | EventCode==11
*Recoder EventCode aux standards INDEPTH
recode EventCode (9=7)(10=9)

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
7 "DTH" 8"-6mDTH" 9 "OBE" 10 "DLV" 11"PREGNANT"18 "OBS" 19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify
label val EventCode eventlab
drop if  EventCode>9
sort IndividualId EventDate EventCode
bys IndividualId EventDate :replace EventCode=2 if EventCode!=2&EventDate==DoB


**Normalement des immigrations [en lieu et place de déménagements. On rentre 
*pour la première fois dans le HDSS par IMG, ENUM, ou BTH et non par ENT.

bys IndividualId : gen a=1 if EventCode[1]==6
br IndividualId EventDate EventCode if a==1
bys IndividualId  : replace EventCode=3 if EventCode[1]==6
bys IndividualId  : replace EventCode=4 if EventCode==5 &  Compound==Compound[_n+1] & EventDate!=EventDate[_n+1]
ta EventCode

rename IndividualId IndividualID
rename Compound locationid
rename HouseholdId socialgpid
rename Sex gender 

keep IndividualID gender DoB EventCode EventDate socialgpid locationid
order IndividualID socialgpid locationid gender DoB EventDate  

gen hdss = "SN01"
tostring IndividualID,replace
tostring socialgpid,replace 
tostring locationid,replace

*Transform all dates in td format
foreach var of varlist  EventDate DoB{
gen double `var'_1 = dofc(`var')
format `var'_1 %td
drop `var'
rename `var'_1 `var'
}
save residency_Niakhar,replace

