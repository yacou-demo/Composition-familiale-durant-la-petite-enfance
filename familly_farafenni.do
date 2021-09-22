use  individual_parents_bis.dta,clear
des motherId
replace motherId="" if motherId=="UNK" | motherId=="unk" | motherId=="Unk"
replace fatherId="" if fatherId=="UNK" | fatherId=="unk" | fatherId=="Unk"

count if fatherId==""
count if motherId==""

count if fatherId==motherId & motherId!="" & fatherId!=""
drop if fatherId==motherId & motherId!="" & fatherId!=""
drop if IndividualId==fatherId & fatherId!="" & IndividualId!=""
drop if IndividualId==motherId & motherId!="" & IndividualId!=""
**Détection des incohérences [1ère etape; basique]
**individus ayant le même identifiant que leurs mères
global coherence = "coherence"
count if IndividualId==motherId /*  0*/
br IndividualId motherId if IndividualId==motherId 

capture export excel IndividualId motherId using $coherence ///
if IndividualId==motherId, firstrow(variables) sh("motherid=IndividualId") 


**individus ayant les mêmes identifiants que leurs pères
count if IndividualId==fatherId /* 0*/
br IndividualId fatherId  if IndividualId==fatherId /* 18*/

capture export excel IndividualId fatherId using $coherence ///
if IndividualId==fatherId, firstrow(variables) sh("fatherId=IndividualId") 

save individual_parents_bis_1,replace


use individual_parents_bis_1,clear
count if IndividualId==""
sort IndividualId 
rename IndividualId IndividualId_1 
count if motherId==""
*Supprimer les individus dont les mères n'ont pas connu un épisode de résidence
drop if motherId==""
rename motherId IndividualId
keep IndividualId IndividualId_1  

merge m:1 IndividualId using individual_parents_bis_1, keep(1 3) keepus(DoB Sex)
*Supprimer les individus ayant le même identifiant que leurs mères
drop if IndividualId==IndividualId_1
save mother_children,replace



use mother_children,clear
keep if _merge==1
*duplicates drop IndividualId,force
save mother_missing_in_resident ,replace

use mother_children,clear
sort IndividualId IndividualId_1
keep if _merge==3
rename DoB DoBMO
rename Sex SexMO
rename  IndividualId motherId
rename  IndividualId_1 IndividualId
label var motherId "Mother ID"
label var DoBMO "Mother DoB"
*keep IndividualId motherId DoBMO SexMO
*Mères de sexe masculin (à transmettre à Baba)
drop _merge
br if SexMO==1

capture export excel IndividualId motherId SexMO using $coherence ///
if SexMO==1, firstrow(variables) sh("mother Sex=M") 

*Individus ayant les mêmes identifiants que leurs mères
br if IndividualId==motherId

save fichier_MO,replace



**Pères
use individual_parents_bis_1,clear
count if IndividualId==""
sort IndividualId 
rename IndividualId IndividualId_1 
count if fatherId==""
*Supprimer les individus dont les mères n'ont pas connu un épisode de résidence
drop if fatherId==""
rename fatherId IndividualId
keep IndividualId IndividualId_1  

merge m:1 IndividualId using individual_parents_bis_1, keep(1 3) keepus(DoB Sex)

*Supprimer les individus ayant les mêmes identifiants que leurs pères
drop if IndividualId==IndividualId_1
save father_children,replace


use father_children,clear
sort IndividualId IndividualId_1
keep if _merge==3
rename DoB DoBFA
rename Sex SexFA
rename  IndividualId fatherId
rename  IndividualId_1 IndividualId
label var fatherId "Father ID"
label var DoBFA "Father DoB"
*keep IndividualId fatherId DoBFA SexFA
*Pères de sexe masculin (à transmettre à Baba)
br if SexFA==2

capture export excel IndividualId fatherId SexFA using $coherence ///
if SexFA==2, firstrow(variables) sh("father Sex="F"") 
drop _merge
save fichier_FA,replace


/*Identification des Grandes mères maternelles qui ont eu au moins un épisode
  de résidence dans la zone*/

use  fichier_MO,clear
keep motherId IndividualId
rename IndividualId ChildId
rename motherId IndividualId
merge m:1 IndividualId using individual_parents_bis_1,keep(1 3) keepus(motherId)gen(mergeGMM)

rename motherId mgmotherId
*rename DoB_mother DoB_mgmother

drop if mgmotherId==""

rename IndividualId motherId
rename mgmotherId IndividualId


merge m:1 IndividualId using individual_parents_bis_1,  keep(1 3) keepus(DoB Sex)gen(mergeMGM)
save MGM_children,replace

use MGM_children,clear
keep if mergeMGM==1
save MGM_missing_in_resident ,replace

use MGM_children,clear
sort IndividualId ChildId 
keep if mergeMGM==3
rename DoB DoBMGM
rename Sex SexMGM

rename IndividualId mgmotherId
rename ChildId IndividualId

label var mgmotherId "Maternal Grand Mother ID"
label var DoBMGM "Maternal Grand Mother DoB"

br if SexMGM==1
capture export excel IndividualId mgmotherId SexMGM using $coherence ///
if  SexMGM==1, firstrow(variables) sh("mgmother Sex="M"") 
*drop _merge


drop merge*
save fichier_MGM,replace


/*Identification des Grands pères paternels qui ont eu au moins un épisode
  de résidence dans la zone*/
 
 
use  fichier_FA,clear
rename IndividualId ChildId
rename fatherId IndividualId
merge m:1 IndividualId using individual_parents_bis_1,keep(1 3) keepus(fatherId)gen(mergeGPP)
 *fatherId pgfatherId
rename fatherId pgfatherId
drop if pgfatherId==""

rename IndividualId fatherId
rename pgfatherId IndividualId

merge m:1 IndividualId using individual_parents_bis_1,  keep(1 3) keepus(DoB Sex)gen(mergePGF)
save PGF_children,replace

use PGF_children,clear
keep if mergePGF==1
save PGF_missing_in_resident ,replace

use PGF_children,clear
sort IndividualId ChildId 
keep if mergePGF==3
rename DoB DoBPGF
rename Sex SexPGF

rename IndividualId pgfatherId
rename ChildId IndividualId

label var pgfatherId "Paternal Grand Father ID"
label var DoBPGF "Paternal Grand Father DoB"
label var SexPGF "Paternal Grand Father Sex"
br if SexPGF==2

capture export excel IndividualId mgmotherId SexPGF using $coherence ///
if  SexPGF==2, firstrow(variables) sh("pgfather Sex="F"") 


*Correction sur un mgfatherId incohérent
*drop if pgfatherId==36989
keep IndividualId SexFA DoBFA DoBPGF SexPGF fatherId pgfatherId 
save fichier_PGF,replace
 
 
 
/*Identification des Grands pères maternels qui ont eu au moins un épisode
  de résidence dans la zone*/
use  fichier_MO,clear
rename IndividualId ChildId
rename motherId IndividualId
merge m:1 IndividualId using individual_parents_bis_1,keep(1 3) keepus(fatherId)gen(mergeGPM)
 *fatherId mgfatherId
rename fatherId mgfatherId
drop if mgfatherId==""

rename IndividualId motherId
rename mgfatherId IndividualId

merge m:1 IndividualId using individual_parents_bis_1,  keep(1 3) keepus(DoB Sex)gen(mergeMGF)
save MGF_children,replace

use MGF_children,clear
keep if mergeMGF==1
save MGF_missing_in_resident ,replace

use MGF_children,clear
sort IndividualId ChildId 
keep if mergeMGF==3
rename DoB DoBMGF
rename Sex SexMGF

rename IndividualId mgfatherId
rename ChildId IndividualId

label var mgfatherId "Maternal Grand Mother ID"
label var DoBMGF "Maternal Grand Mother DoB"
label var SexMGF "Maternal Grand Father Sex"
br if SexMGF==2

capture export excel IndividualId mgfatherId SexMGF using $coherence ///
if  SexMGF==2, firstrow(variables) sh("mgfatherId Sex="F"") 


*Correction sur un mgfatherId incohérent
*drop if mgfatherId==1078189
keep IndividualId SexMO DoBMO DoBMGF SexMGF motherId mgfatherId 
save fichier_MGF,replace
  
 

/*Identification des Grandes mères paternels qui ont eu au moins un épisode
  de résidence dans la zone*/



use  fichier_FA,clear
rename IndividualId ChildId
rename fatherId IndividualId
merge m:1 IndividualId using individual_parents_bis_1,keep(1 3) keepus(motherId)gen(mergeGMP)

rename motherId pgmotherId
drop if pgmotherId==""

rename IndividualId fatherId
rename pgmotherId IndividualId

merge m:1 IndividualId using individual_parents_bis_1,  keep(1 3) keepus(DoB Sex)gen(mergePGM)
save PGM_children,replace

use PGM_children,clear
keep if mergePGM==1
save PGM_missing_in_resident ,replace

use PGM_children,clear
sort IndividualId ChildId 
keep if mergePGM==3
rename DoB DoBPGM
rename Sex SexPGM

rename IndividualId pgmotherId
rename ChildId IndividualId

label var pgmotherId "Paternal Grand Mother ID"
label var DoBPGM "Paternal Grand Mother DoB"

br if SexPGM==1

capture export excel IndividualId pgmotherId SexPGM using $coherence ///
if  SexPGM==1, firstrow(variables) sh("pgmotherId Sex="F"") 

keep IndividualId SexFA DoBFA DoBPGM SexPGM fatherId pgmotherId 
save fichier_PGM, replace

/*Organisation de tous ces fichiers*/



use individual_parents_bis_1,clear
sort IndividualId
merge 1:1 IndividualId using fichier_FA, keepus(fatherId SexFA DoBFA) gen (merge_FA)
merge 1:1 IndividualId using fichier_MO, keepus(motherId SexMO DoBMO) gen (merge_MO)
merge 1:1 IndividualId using fichier_MGM, keepus(mgmotherId DoBMGM SexMGM) gen (merge_MGM)
merge 1:1 IndividualId using fichier_MGF, keepus(mgfatherId DoBMGF SexMGF) gen(merge_MGF)
merge 1:1 IndividualId using fichier_PGF, keepus(pgfatherId DoBPGF SexPGF) gen(merge_PGF)
merge 1:1 IndividualId using fichier_PGM, keepus(pgmotherId DoBPGM SexPGM) gen(merge_PGM)


/*
foreach var of varlist DoB DoBMO DoBFA DoBMGM DoBMGF DoBPGF DoBPGM{

gen `var'_1 =  date(`var',"DMY",2050) 

format `var'_1 %td
drop `var'
rename `var'_1 `var'
}
*/
*rename uuid individual_uuid
save family_Farafenni_all_var,replace

keep IndividualId DoB Sex  fatherId DoBFA motherId DoBMO mgmotherId DoBMGM SexMGM mgfatherId DoBMGF SexMGF pgfatherId DoBPGF SexPGF pgmotherId DoBPGM SexPGM

save family_Farafenni, replace



**Détection des incohérences [1ère etape; basique]
**individus ayant le même identifiant que leurs mères

use family_Farafenni,clear
br IndividualId fatherId DoB DoBFA if DoB < DoBFA & DoBFA!=.

capture export excel IndividualId fatherId DoB DoBFA using $coherence ///
if DoB < DoBFA & DoBFA!=., firstrow(variables) sh("DoB>DoBFA") 

*Older than his father
br IndividualId fatherId DoB DoBFA if DoB < DoBFA & DoBFA!=.
capture export excel IndividualId fatherId DoB DoBFA using $coherence ///
if DoB < DoBFA & DoBFA!=., firstrow(variables) sh("DoB>DoBFA") 


*Older than his mother
br IndividualId motherId DoB DoBMO if DoB < DoBMO & DoBMO!=.
capture export excel IndividualId fatherId DoB DoBFA using $coherence ///
if DoB < DoBMO & DoBMO!=., firstrow(variables) sh("DoB>DoBMO") 

*Older than his mother
br IndividualId motherId DoB DoBMO if DoB < DoBMO & DoBMO!=.
capture export excel IndividualId motherId DoB DoBFA using $coherence ///
if DoB < DoBMO & DoBMO!=., firstrow(variables) sh("DoB>DoBMO") 


*Older than his maternal grand mother
br IndividualId mgmotherId DoB DoBMGM if DoB < DoBMGM & DoBMGM!=.
capture export excel IndividualId mgmotherId DoB DoBMGM using $coherence ///
if DoB < DoBMGM & DoBMGM!=., firstrow(variables) sh("DoB>DoBMGM") 

*Older than his maternal grand father
br IndividualId mgfatherId DoB DoBMGF if DoB < DoBMGF & DoBMGF!=.
capture export excel IndividualId mgfatherId DoB DoBMGF using $coherence ///
if DoB < DoBMGF & DoBMGF!=., firstrow(variables) sh("DoB>DoBMGF") 


*Older than his paternal grand mother
br IndividualId pgmotherId DoB DoBPGM if DoB < DoBPGM & DoBPGM!=.
capture export excel IndividualId pgmotherId DoB DoBPGM using $coherence ///
if DoB < DoBPGM & DoBPGM!=., firstrow(variables) sh("DoB>DoBPGM") 

*Older than his paternal grand father
br IndividualId pgfatherId DoB DoBPGF if DoB < DoBPGF & DoBPGF!=.
capture export excel IndividualId pgfatherId DoB DoBPGF using $coherence ///
if DoB < DoBPGF & DoBPGF!=., firstrow(variables) sh("DoB>DoBPGF") 

sort IndividualId 
merge 1:m IndividualId using residency_Farafenni ,keepus(socialgpid)gen(merge_sgp)
sort IndividualId 

rename socialgpid socialgpId
drop if fatherId=="" & motherId==""& pgfatherId=="" & pgmotherId=="" & mgfatherId =="" & mgmotherId==""

save familly_Farafenni_final, replace


**Oncles, cousins et tantes
use familly_Farafenni_final,clear


duplicates drop socialgpId IndividualId,force
**Oncles et tantes paternelles
*drop if pgmotherId==""
*nombre de petits enfants
bys socialgpId : gen nbg_children = _N
*keep IndividualId pgmotherId DoB
**Nombre de petits fils
*bys pgmotherId: gen hh_size = _N
expand nbg_children if nbg_children!=.
order socialgpId IndividualId 
sort socialgpId IndividualId 
by socialgpId IndividualId: gen ind_dup = _n
order socialgpId IndividualId ind_dup nbg_children

by socialgpId: gen IndividualId_egoB = IndividualId[nbg_children * ind_dup]
order socialgpId IndividualId IndividualId_egoB ind_dup nbg_children


order socialgpId IndividualId ind_dup IndividualId_egoB

bys socialgpId: gen fatherId_egoB = fatherId[nbg_children * ind_dup]

bys socialgpId: gen motherId_egoB = motherId[nbg_children * ind_dup]

bys socialgpId: gen Sex_egoB = Sex[nbg_children * ind_dup]

bys socialgpId: gen DoB_egoB = DoB[nbg_children * ind_dup]


order socialgpId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children 

	  
	  
br socialgpId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children 
	  
	  

*Suprimer les couple (i,i) ?[les garder car certains sont des ménages d'une personne)]
drop if IndividualId == IndividualId_egoB

order socialgpId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children 


gen puncleid_ego = ""
gen DoB_puncle=.

gen muncleid_ego = ""
gen DoB_muncle=.

gen paunt_ego=""
gen DoB_paunt=.

gen maunt_ego=""
gen DoB_maunt=.
drop if fatherId=="" & motherId==""& pgfatherId=="" & pgmotherId=="" & mgfatherId =="" & mgmotherId==""

save file_for_other_sibling,replace

/*
Contruction du fichier des oncles et des tantes paternelles à partir de
la grande mère.
*/

use file_for_other_sibling,clear
* Le frère de mon père est mon oncle paternel [il a la même mère que mon père ou le même père que mon père]
replace puncleid_ego = IndividualId_egoB if (pgmotherId == motherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & pgmotherId!="" & fatherId!="" 
replace puncleid_ego = IndividualId_egoB if	(pgfatherId == fatherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & pgfatherId!="" & fatherId!=""

	
	
* Le frère de mon père est mon oncle paternel [il a la même mère que mon père]
replace DoB_puncle = DoB_egoB if (pgmotherId == motherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & pgmotherId!="" & fatherId!="" 
replace DoB_puncle = DoB_egoB if (pgfatherId == fatherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & pgfatherId!="" & fatherId!=""

											
	
order pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children 
											
											
br pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children puncleid_ego if puncleid_ego!=""
		
drop if puncleid_ego==""

order pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children 
											
											
br pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children puncleid_ego paunt_ego
	  
	  
keep IndividualId DoB Sex   puncleid_ego   DoB_puncle 

											
* just to fill missing values
bys  IndividualId :gen round=_n
ta round
scalar n =`r(r)'
reshape wide  puncleid_ego  DoB_puncle  ,i(IndividualId)j(round) 
								
format DoB_puncle* %td
save family_Farafenni_puncle,replace
									
											
											
** Paternal Aunt
use file_for_other_sibling,clear
					
* La soeur de mon père est ma tante paternelle [elle a la même mère que mon père ou le même père que mon père]
replace paunt_ego = IndividualId_egoB if (pgmotherId == motherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & pgmotherId!="" & motherId!="" 
											
replace paunt_ego = IndividualId_egoB if (pgfatherId == fatherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & pgfatherId!="" & motherId!=""
									

* La soeur de mon père est ma tante paternelle [elle a la même mère que mon père]
replace DoB_paunt = DoB_egoB if (pgmotherId == motherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & pgmotherId!="" & motherId!=""	
									        
replace DoB_paunt = DoB_egoB if	(pgfatherId == fatherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & pgfatherId!="" & motherId!=""
											
drop if paunt_ego=="" 


order pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children 
											
											
br pgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children  paunt_ego
	  
	  
keep IndividualId DoB Sex paunt_ego DoB_paunt 



bys  IndividualId :gen round=_n
ta round
scalar n =`r(r)'
reshape wide  paunt_ego DoB_paunt,i(IndividualId)j(round) 

format DoB_paunt* %td
save family_Farafenni_paunt,replace
	
	
** Maternal uncle	
/*
Contruction du fichier des oncles et des tantes maternelles à partir de
*/
use file_for_other_sibling,clear
* Le frère de ma mère est mon oncle maternel [il a la même mère que ma mère ou le même père que ma mère]
replace muncleid_ego = IndividualId_egoB if (mgmotherId == motherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & mgmotherId!="" & fatherId!="" 
replace muncleid_ego = IndividualId_egoB if	(mgfatherId == fatherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & mgfatherId!="" & fatherId!=""

	
	
*Le frère de mon père est mon oncle paternel [il a la même mère que mon père]
replace DoB_muncle = DoB_egoB if (mgmotherId == motherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & mgmotherId!="" & fatherId!="" 
replace DoB_muncle = DoB_egoB if (mgfatherId == fatherId_egoB) & ///
                                            (fatherId!=IndividualId_egoB) & ///
											(Sex_egoB==1) & mgfatherId!="" & fatherId!=""

											
drop if muncleid_ego=="" 
	
order mgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children 
											
											
br mgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB DoB_egoB ind_dup nbg_children muncleid_ego if muncleid_ego!=""
											
	
keep IndividualId DoB Sex   muncleid_ego DoB_muncle 
sort IndividualId muncleid_ego 
bys IndividualId  :gen round=_n
ta round
scalar n =`r(r)'
reshape wide  muncleid_ego  DoB_muncle  ,i(IndividualId)j(round) 

format DoB_muncle* %td
save family_Farafenni_muncle,replace



use file_for_other_sibling,clear
*La soeur de ma mère est ma tante maternelle [elle a la même mère que ma mère ou le même père que ma mère]
replace maunt_ego = IndividualId_egoB if (mgmotherId == motherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & mgmotherId!="" & motherId!="" 
replace maunt_ego = IndividualId_egoB if (mgfatherId == fatherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & mgfatherId!="" & motherId!=""
									

* La soeur de mon père est ma tante paternelle [elle a la même mère que mon père]
replace DoB_maunt = DoB_egoB if (mgmotherId == motherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & mgmotherId!="" & motherId!=""	
replace DoB_maunt = DoB_egoB if	(mgfatherId == fatherId_egoB) & ///
                                            (motherId!=IndividualId_egoB) & ///
											(Sex_egoB==2) & mgfatherId!="" & motherId!=""
											
drop if maunt_ego=="" 


order mgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children 
											
											
br mgmotherId IndividualId IndividualId_egoB fatherId fatherId_egoB ///
      motherId motherId_egoB Sex Sex_egoB ind_dup nbg_children  maunt_ego
	  
keep IndividualId DoB Sex maunt_ego DoB_maunt 
sort IndividualId  maunt_ego 
bys IndividualId :gen round=_n
ta round
scalar n =`r(r)'
reshape wide   maunt_ego DoB_maunt,i(IndividualId)j(round) 


format DoB_maunt* %td
save family_Farafenni_maunt,replace


****Farafenni Familly

use familly_Farafenni_final,clear
duplicates drop    IndividualId,force
sort   IndividualId 
merge 1:1  IndividualId using family_Farafenni_puncle,gen(mergep)
sort  IndividualId
merge 1:1  IndividualId using family_Farafenni_paunt,gen(mergea)
sort  IndividualId
merge 1:1  IndividualId using family_Farafenni_muncle,gen(mergem)
sort  IndividualId
merge 1:1  IndividualId using family_Farafenni_maunt,gen(mergema)
drop merge*
foreach var of varlist motherId fatherId pgfatherId pgmotherId mgfatherId mgmotherId {
bysort IndividualId : replace `var' = `var'[1]
bysort IndividualId : replace `var' = `var'[1]
}
count if motherId=="" & fatherId==""
save familly_Farafenni_fnetwork, replace



	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	




















