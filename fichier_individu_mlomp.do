use  ident_mlomp,clear
rename ego IndividualId

tostring jnais,replace
tostring mnais,replace
tostring anais,replace
replace jnais = "0" + jnais if length(jnais)==1
replace mnais = "0" + mnais if length(mnais)==1
br jnais mnais anais
replace jnais="00" if jnais=="0."
replace  mnais="00" if  mnais=="0."
egen birth_date = concat(jnais mnais anais)
gen birth_date_1 =  date(birth_date,"DMY",2050) 
format birth_date_1 %td
count if birth_date==""
duplicates list IndividualId
duplicates drop IndividualId,force
sort IndividualId
drop in 38485

rename men  HouseholdId
destring HouseholdId,replace

keep IndividualId pere mere birth_date_1 HouseholdId sexe
save Individual_2,replace