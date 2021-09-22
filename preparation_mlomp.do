use  MLOMP_resid_propre_complet_.dta,clear

ta EventCode
*Suppresion des événements dont je n'ai pas besoin
sort IndividualId EventDate EventCode
ta EventCode
ta EventCode,nol
drop if EventCode== 7 | EventCode== 8 |  EventCode== 12 | EventCode==26 | EventCode==11
*Recoder EventCode aux standards INDEPTH
recode EventCode (9=7)(10=9)

label define eventlab 1 "ENU" 2 "BTH" 3 "IMG" 4 "OMG" 5 "EXT" 6 "ENT" ///
7 "DTH" 8"-6mDTH" 9 "OBE" 10 "DLV" 11"PREGNANT"18 "OBS" ///
19 "OBL" 20 "1Jan" 21 "NewAgeGroup", modify

drop if EventCode>9

rename HouseholdId socialgpid
rename LocationId locationid
rename Sex gender
rename IndividualId IndividualID 
tostring IndividualID,replace
tostring socialgpid,replace 
tostring locationid,replace


keep IndividualID gender DoB EventCode EventDate socialgpid locationid
order IndividualID socialgpid locationid gender DoB EventDate  
*Transform all dates in td format
foreach var of varlist  EventDate DoB{
gen double `var'_1 = dofc(`var')
format `var'_1 %td
drop `var'
rename `var'_1 `var'
}
gen hdss = "SN02"

*313 missing values pour mlomp
save residency_Mlomp,replace