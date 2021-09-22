*-------------------------------------------------------------------------------
                       **Child - Parents 
*-------------------------------------------------------------------------------
cd"C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\maunts"
local originals "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\maunts" // OR WHATEVER THE RIGHT DIRECTORY IS.
local files: dir "`originals'" files "child_maunt_*.dta" // NOTE : after C
local dir1 "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\output" // LOCALS ARE SAFER THAN GLOBALS
local dir2 "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\maunts"


*tempfile building
*save `building', emptyok


foreach f of local files {
     use `"`originals'/`f'"', clear // NOTE USE OF /, NOT \, AS SEPARATOR!!!
	 
	   local w = strreverse(substr(strreverse(substr(`"`f'"', 13, .)), 5,.))
di "`w'"


	  
}

  

use child_mother_sahel,clear
sort IndividualId EventDate EventCode
capture drop dup_a
quietly by IndividualId EventDate EventCode: gen dup_a = cond(_N==1,0,_n)

*drop if dup_a>1

duplicates drop hdss IndividualId,force

save child_mother_sahel_unique,replace

use  child_father_sahel.dta,clear

sort IndividualId EventDate EventCode
quietly by IndividualId EventDate EventCode: gen dup_b = cond(_N==1,0,_n)
*drop if dup_b>1

duplicates drop hdss IndividualId,force
keep IndividualId hdss
save child_father_sahel_unique,replace

use child_mother_sahel_unique,clear
sort IndividualId
merge 1:1 hdss IndividualId using child_father_sahel_unique
keep if _merge==2
rename _merge merge_add
append using child_mother_sahel.dta, gen(append1)

/*
*Censor date (01/01/2018)
capture drop last_record_date_1
gen double last_record_date_1 = cofd(date("01Jan 2018","DMY",2020))
format last_record_date_1 %tc
display %20.0f clock("1Jan2018","DMY") /* Date de début */
*/
ta hdss last_record_date,nol

display %20.0f date("01Jan 2016","DMY") /*20454*/
display %20.0f date("01Jan 2018","DMY") /*21185*/
display %20.0f date("29aug2018","DMY") /*21425*/ 
display %20.0f date("19apr2019","DMY") /*21658*/ 

count if EventDate==.

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5

replace EventDate = last_record_date if EventDate==.


foreach var of varlist EventCode EventCodeMO   {  
recode  `var' .=9 if append1==0
}
recode residenceMO (.=0) if append1==0

sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventCode EventCodeMO {  
replace  `var'=9 if duplicate==1
}

drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save child_mother_sahel_bis,replace



use child_father_sahel_unique,clear
sort IndividualId
merge 1:1 hdss IndividualId using child_mother_sahel_unique
keep if _merge==2
rename _merge merge_add
append using child_father_sahel,gen(append2)

ta hdss last_record_date,nol

display %20.0f date("01Jan 2016","DMY") /*20454*/
display %20.0f date("01Jan 2018","DMY") /*21185*/
display %20.0f date("29aug2018","DMY") /*21425*/ 
display %20.0f date("19apr2019","DMY") /*21658*/ 

count if EventDate==.

bys IndividualId : replace last_record_date=21658  if EventDate==. & hdss==1
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==2
bys IndividualId : replace last_record_date=21425  if EventDate==. & hdss==3
bys IndividualId : replace last_record_date=20454  if EventDate==. & hdss==4
bys IndividualId : replace last_record_date=21185  if EventDate==. & hdss==5

replace EventDate = last_record_date if EventDate==.


foreach var of varlist EventCode EventCodeFA   {  
recode  `var' .=9 if append2==0
}
recode residenceFA (.=0) if append2==0

sort hdss IndividualId EventDate EventCode
expand=2 if IndividualId!=IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort IndividualId EventDate EventCode duplicate
by IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort IndividualId EventDate EventCode
bys IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventCode EventCodeFA {  
replace  `var'=9 if duplicate==1
}

drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

rename EventDate EventDate1
rename EventCode EventCode1
save child_father_sahel_bis, replace


/***********************TMERGE*******************************/
capture erase child_parents_sahel.dta
clear
capture erase child_parents_sahel.dta
tmerge  IndividualId child_mother_sahel_bis(EventDate) child_father_sahel_bis(EventDate1) ///
		child_parents_sahel(EventDate_final)


	
		
format EventDate_final %td
drop EventDate EventDate1
rename EventDate_final EventDate

replace EventCode = 18 if _File==2

replace EventCodeMO = 18 if _File==2
replace EventCode1 = 18 if _File==1

replace EventCodeFA = 18 if _File==1


capture drop dup_e
sort IndividualId EventDate EventCode
 by IndividualId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

*drop if dup_e>1

order IndividualId EventDate EventCode
sort IndividualId EventDate EventCode
rename _File child_parents_sahel
		

drop if MotherId==""
replace  coresidFA=0 if  FatherId==""

save child_parents_sahel_final,replace



