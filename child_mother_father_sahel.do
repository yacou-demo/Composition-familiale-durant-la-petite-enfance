*-------------------------------------------------------------------------------
                       **Child - Parents 
*-------------------------------------------------------------------------------
*modif
use child_mother_sahel_clean,clear
sort concat_IndividualId EventDate EventCode
capture drop dup_a
quietly by concat_IndividualId EventDate EventCode: gen dup_a = cond(_N==1,0,_n)

*drop if dup_a>1

duplicates drop concat_IndividualId,force
keep concat_IndividualId hdss
save child_mother_sahel_unique,replace

use  child_father_sahel_clean.dta,clear

sort concat_IndividualId EventDate EventCode
quietly by concat_IndividualId EventDate EventCode: gen dup_b = cond(_N==1,0,_n)
*drop if dup_b>1
*modif
duplicates drop concat_IndividualId,force
*modif
keep concat_IndividualId hdss
save child_father_sahel_unique,replace

*modif
use child_mother_sahel_unique,clear
sort concat_IndividualId
merge 1:1 concat_IndividualId using child_father_sahel_unique
keep if _merge==2
rename _merge merge_add
append using child_mother_sahel_clean.dta, gen(append1)

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

bys concat_IndividualId : replace last_record_date=21658  if EventDate==. & hdss=="GM011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="BF041"
bys concat_IndividualId : replace last_record_date=21425  if EventDate==. & hdss=="BF021"
bys concat_IndividualId : replace last_record_date=20454  if EventDate==. & hdss=="SN011"
bys concat_IndividualId : replace last_record_date=21185  if EventDate==. & hdss=="SN012"

replace EventDate = last_record_date if EventDate==.


foreach var of varlist EventCode EventCodeMO   {  
recode  `var' .=9 if append1==0
}
recode residenceMO (.=0) if append1==0

sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bys hdss concat_IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventCode EventCodeMO {  
replace  `var'=9 if duplicate==1
}

drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

save child_mother_sahel_bis,replace


*modif
use child_father_sahel_unique,clear
sort concat_IndividualId
merge 1:1 concat_IndividualId using child_mother_sahel_unique
keep if _merge==2
rename _merge merge_add
append using child_father_sahel_clean,gen(append2)

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


foreach var of varlist EventCode EventCodeFA   {  
recode  `var' .=9 if append2==0
}
recode residenceFA (.=0) if append2==0

sort hdss concat_IndividualId EventDate EventCode
expand=2 if concat_IndividualId!=concat_IndividualId[_n+1] & EventDate<last_record_date, gen(duplicate)
sort concat_IndividualId EventDate EventCode duplicate
by concat_IndividualId : replace EventDate=last_record_date  if duplicate==1

* Need recoding for these individuals
sort hdss concat_IndividualId EventDate EventCode
bys hdss concat_IndividualId : replace EventCode=9 if _n==_N


foreach var of varlist EventCode EventCodeFA {  
replace  `var'=9 if duplicate==1
}

drop duplicate

* to check that all EventDate end up 1 Jan 2016 except for non-resident mothers
capture drop maxEventDate
bysort hdss concat_IndividualId (EventDate) : egen double maxEventDate=max(EventDate)
format %td maxEventDate
tab maxEventDate, miss

rename EventDate EventDate1
rename EventCode EventCode1
save child_father_sahel_bis, replace


/***********************TMERGE*******************************/
capture erase child_parents_sahel.dta
clear
capture erase child_parents_sahel.dta
tmerge  concat_IndividualId child_mother_sahel_bis(EventDate) child_father_sahel_bis(EventDate1) ///
		child_parents_sahel(EventDate_final)


	
		
format EventDate_final %td
drop EventDate EventDate1
rename EventDate_final EventDate

replace EventCode = 18 if _File==2

replace EventCodeMO = 18 if _File==2
replace EventCode1 = 18 if _File==1

replace EventCodeFA = 18 if _File==1


capture drop dup_e
sort concat_IndividualId EventDate EventCode
 by concat_IndividualId EventDate EventCode: gen dup_e= cond(_N==1,0,_n)

*drop if dup_e>1

order concat_IndividualId EventDate EventCode
sort concat_IndividualId EventDate EventCode
rename _File child_parents_sahel
		

drop if MotherId==""
replace  coresidFA=0 if  FatherId==""
save child_parents_sahel_final,replace



