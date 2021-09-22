*Farafenni - 1
use residency_Farafenni.dta,clear
drop hdss
gen hdss = 1
save residency_Farafenni.dta_final,replace

*Niakhar - 4
use residency_Niakhar.dta,clear
recode gender (-1 = 1) 
drop hdss
gen hdss = 4
save residency_Niakhar_final, replace

*Ouagadougou - 3
use residency_Ouaga,clear
drop hdss
gen hdss = 3
save residency_Ouaga_final,replace

*Nanoro - 2
use residency_Nanoro,clear
gen gender_2 = cond(gender=="F",2,1)
drop gender
rename gender_2 gender
*Transform all dates in td format
foreach var of varlist  EventDate DoB{
gen double `var'_1 = dofc(`var')
format `var'_1 %td
drop `var'
rename `var'_1 `var'
}

drop hdss
gen hdss = 2
save residency_Nanoro_final, replace

*Mlomp - 5
use residency_Mlomp
drop if gender==9 | gender==0

drop hdss
gen hdss = 5
save residency_Mlomp_final,replace

*Farafenni
use residency_Farafenni.dta_final,clear
append using residency_Niakhar_final
append using residency_Ouaga_final
append using residency_Nanoro_final
append using residency_Mlomp_final
label define gender 1"Male" 2"Female", modify
label val gender gender
label define hdss 1"Farafenni" 2"Nanoro" 3"Ouaga" 4"Niakhar" 5"Mlomp"
label val hdss hdss
ta hdss

egen concat_IndividualId = concat(hdss IndividualID)
save residency_final_5HDSS,replace


**Familly

*Farefenni
use familly_Farafenni_fnetwork.dta,clear
drop if  socialgpId==""
des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
gen hdss = 1
save familly_Farafenni_fnetwork_final,replace

*Nanoro
use familly_Nanoro_fnetwork.dta,clear
des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
gen hdss = 2

foreach var of varlist Sex SexMGM SexMGF SexPGF SexPGM {
gen `var'_2 = cond(`var'=="F",2,1)
drop `var' 
rename `var'_2 `var'
}
save familly_Nanoro_fnetwork_final,replace

*Ouagadougou

use familly_Ouaga_fnetwork.dta,clear
des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
gen hdss = 3

save familly_Ouaga_fnetwork_final,replace

*Niakhar
use familly_Niakhar_fnetwork.dta,clear

des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
gen hdss = 4

foreach var of varlist Sex SexMGM SexMGF SexPGF SexPGM {
drop if `var'=="-1" | `var'=="0" 
gen `var'_2 = cond(`var'=="F",2,1)
drop `var' 
rename `var'_2 `var'
}

save familly_Niakhar_fnetwork_final,replace

*Mlomp
use familly_Mlomp_fnetwork.dta,clear
drop if socialgpId==""
tostring socialgpId,replace
des IndividualId motherId fatherId mgmotherId mgfatherId pgfatherId pgmotherId ///
puncleid_ego* paunt_ego* maunt_ego* muncleid_ego*
gen hdss = 5
save familly_Mlomp_fnetwork_final,replace

use familly_Farafenni_fnetwork_final,clear
append using familly_Ouaga_fnetwork_final
append using familly_Nanoro_fnetwork_final
append using familly_Niakhar_fnetwork_final
append using familly_Mlomp_fnetwork_final

label define hdss 1"Farafenni" 2"Nanoro" 3"Ouaga" 4"Niakhar" 5"Mlomp"
label val hdss hdss
ta hdss, m
label define Sex 1"Male" 2"Female", modify
label val Sex Sex

*correstions
egen f = concat(hdss fatherId socialgpId)
egen m = concat(hdss motherId socialgpId)
count if m==f & fatherId!="" & motherId!=""
drop if pgfatherId==pgmotherId & pgfatherId!="" & pgmotherId!=""

forvalues i=1/10{
count if puncleid_ego`i'==puncleid_ego`i+1' & puncleid_ego`i'!=""& puncleid_ego`i+1'!=""
}

drop if fatherId=="" & motherId==""

duplicates drop hdss IndividualId socialgpId fatherId motherId puncleid_ego1 paunt_ego1 muncleid_ego1 maunt_ego1,force
egen concat_IndividualId = concat(hdss IndividualId)
save familly_final_5HDSS,replace


