cd"C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\paunts"
local originals "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\paunts" // OR WHATEVER THE RIGHT DIRECTORY IS.
local files: dir "`originals'" files "child_paunt_*.dta" // NOTE : after C
local dir1 "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\output" // LOCALS ARE SAFER THAN GLOBALS
local dir2 "C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data\muncles"

use child_network_pu.dta,clear
tempfile building
save `building', emptyok

foreach f of local files {
	   
local w = strreverse(substr(strreverse(substr(`"`f'"', 13, .)), 5,.))

use `"`building'"',clear
sort concat_IndividualId EventDate EventCode
capture drop dup_a
quietly by concat_IndividualId EventDate EventCode: gen dup_a = cond(_N==1,0,_n)
*drop if dup_a>1
duplicates drop hdss  concat_IndividualId,force
save `"`building'_unique"', replace


use `"`originals'/`f'"', clear
sort concat_IndividualId EventDate EventCode
duplicates drop hdss  concat_IndividualId,force
keep concat_IndividualId hdss 
save `"`f'_unique"', replace

use `"`building'_unique"',clear

merge 1:1 hdss  concat_IndividualId using `"`f'_unique"'
keep if _merge==2
rename _merge mergepa`w'
append using `building', gen(appendpa_`w')

ta hdss last_record_date,nol

display %20.0f date("01Jan 2016","DMY") /*20454*/
display %20.0f date("01Jan 2018","DMY") /*21185*/
display %20.0f date("29aug2018","DMY") /*21425*/ 
display %20.0f date("19apr2019","DMY") /*21658*/ 

count if EventDate==.

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"

replace EventDate = last_record_date if EventDate==.

recode  EventC* (.=9) if appendpa_`w'==0
recode resid* (.=0) if appendpa_`w'==0


sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bysort hdss concat_IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventC* {  
replace  `var'=9 if duplicate==1
}
drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save child_network_sahel_bis,replace


use `"`f'_unique"',clear
sort concat_IndividualId
merge 1:1 hdss  concat_IndividualId using `"`building'_unique"'
keep if _merge==2
rename _merge mergepa1_`w'
append using `"`f'"',gen(appendpa1__`w')

ta hdss last_record_date,nol

display %20.0f date("01Jan 2016","DMY") /*20454*/
display %20.0f date("01Jan 2018","DMY") /*21185*/
display %20.0f date("29aug2018","DMY") /*21425*/ 
display %20.0f date("19apr2019","DMY") /*21658*/ 

count if EventDate==.

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"

replace EventDate = last_record_date if EventDate==.

recode  EventC* (.=9) if appendpa1__`w'==0
recode resid* (.=0) if   appendpa1__`w'==0

sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bys hdss concat_IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventC* {  
replace  `var'=9 if duplicate==1
}

drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

rename EventDate EventDate1
*rename EventCode EventCode1
save child_aunt`w'_sahel_bis, replace


/***********************TMERGE*******************************/
capture erase building_a.dta
clear
capture erase building_a.dta
tmerge  concat_IndividualId child_network_sahel_bis(EventDate) child_aunt`w'_sahel_bis(EventDate1) ///
		building_a.dta(EventDate_final)


format EventDate_final %td
drop EventDate EventDate1
rename EventDate_final EventDate

replace EventCode = 18 if _File==2

replace EventDatepaunt`w' = 18 if _File==2
capture drop dup_e
sort concat_IndividualId EventDate EventCode
bysort concat_IndividualId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

*drop if dup_e>1

order concat_IndividualId EventDate EventCode
sort concat_IndividualId EventDate EventCode
rename _File aunt`w'
		

drop if MotherId==""
*replace  coresidFA=0 if  FatherId==""

save `"`building'"', replace
}

label data "file_paunts, long format"
save `"`dir1'/child_network_pa_paunt.dta"', replace
save `"`dir2'/child_network_pa_paunt.dta"', replace

cd"C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 1\data\Final data" // OR WHATEVER THE RIGHT DIRECTORY IS.
shell rd "paunts" /s /q 










