**Data analysis
use final_dataset_analysis_des,clear




*Transform dates to %tc
foreach w of varlist EventDate DoB*{
gen double `w'_1 = cofd(`w')
format `w'_1 %tc
drop `w' 
rename `w'_1 `w'
}

*Add 12  hours to ENT
sort  concat_IndividualId EventDate EventCode 
bys concat_IndividualId : replace EventDate=EventDate+12*60*60*1000 if EventCode==6&EventCode[_n-1]==5

display %20.0f 365.25*24*60*60*1000

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 


stset EventDate, id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB)  scale(31557600000) 
		
**Nombre de naissances par hdss
bys hdss : ta  EventCode _st 

*Samble description
bys hdss : stdes 


* Période d'analyse- 01 jan 2009 - 01 Jan 2016
forval num=2009/2016 {
display %20.0f date("01Jan`num':","DMY")
}

capture drop entry_time
gen entry_time = 17898
format entry_time %td
gen double entry_time_1 = cofd(entry_time)
format entry_time_1 %tc
drop entry_time

capture drop exit_time
gen exit_time = 20454
format exit_time %td
gen double exit_time_1 = cofd(exit_time)
format exit_time_1 %tc
drop exit_time





forval num=2009/2016 {
display %20.0f clock("01Jan`num':","DMY")
}
sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 

sort concat_IndividualId EventDate EventCode
capture drop entry_d
bys concat_IndividualId : gen entry_d = (EventDate[1]>=entry_time_1)

capture drop exit_d
gen exit_d = (EventDate>=exit_time_1)

stset EventDate, id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB)  scale(31557600000) entry(entry_d=1) exit(time exit_time_1)
		
**Nombre de naissances par hdss
bys hdss : ta  EventCode _st if entry_d==1 & DoB<=exit_time_1


capture drop hdss_2
gen hdss_2 = 1 if hdss=="BF021"
replace hdss_2 = 2 if hdss=="BF041"
replace hdss_2 = 3 if hdss=="GM011"
replace hdss_2 = 4 if hdss=="SN011"
replace hdss_2 = 5 if hdss=="SN012"
 
label define hdss_2 1"Ouagadougou" 2"Nanoro" 3"Farafenni" 4"Niakhar" 5"Mlomp",modify
label val hdss_2 hdss_2
compress
save final_dataset_analysis,replace

* begin here []
use final_dataset_analysis,clear

capture drop wage
gen wage = _t-_t0

*Sample description
*bys hdss_2 : stdes 


********************************************************************************
                        ** Descriptive analysis
********************************************************************************

********************** *Création des typologies*********************************

*Typologie 1
*presence des parents
*Coresident with parents
replace coresidFA = 2 if coresidFA==1

ta coresidFA coresidMO 
capture drop hh_comp
gen hh_comp = coresidFA + coresidMO

ta hh_comp, m 
label define hhcomp 0"No parents" 1"Mother only" 2"Father only" ///
             3"Both parents", modify
			 
label define hhcompf 0"Aucun parent" 1"Mère seule" 2"Père seul" ///
3"Père et Mère", modify

label val hh_comp hhcomp

*Proportion des enfants vivant avec leurs parents
ta hh_comp hdss_2 [iw = _t-_t0],col


*Typologie 2
 *Paternal and Maternal relatives bilateral no relatives
 capture drop hh_type_2
 gen hh_type_2 = 0 if  presence_PLK==0 & presence_MLK==0
 
 replace hh_type_2 = 1 if presence_PLK==1  & presence_MLK==0
 
 replace hh_type_2 = 2 if  presence_MLK==1 & presence_PLK==0
 
 replace hh_type_2 = 3 if  presence_MLK==1 &  presence_PLK==1

label define hh_type_2 0"No relatives" 1"Paternal relatives" 2"Maternal relatives" 3"bilateral relatives",modify
label val hh_type_2 hh_type_2

ta hh_type_2 hdss_2 [iw = _t-_t0],col

*Typologie 3
*Children with only grand father
capture drop hh_type3
gen hh_type3 = 0
replace hh_type3 = 1 if (coresidMGF==1 | coresidPGF==1) & (coresidMGM==0 & coresidPGM==0)
replace hh_type3 = 2 if (coresidMGM==1 | coresidPGM==1) & (coresidMGF==0 & coresidPGF==0)
replace hh_type3 = 3 if (coresidMGF==1 | coresidPGF==1) & (coresidMGM==1 | coresidPGM==1)

label define hh_type3 0"No Grand-parents" 1"Grand-father only" 2"Grand-mother only" 3"Grand mother and Grand father" ///
, modify
label val hh_type3 hh_type3

ta hh_type3 hdss_2 [iw = _t-_t0],col

capture drop minwage
bysort concat_IndividualId: egen minwage = min(wage) if hh_comp==0

*bys hdss_2 hh_comp: stdes

*For all children 
* For all
capture drop wage
gen wage = _t-_t0

*At birth
capture drop wage2
gen wage2=1

/*
graph bar (count) wage  [pw = _t-_t0] , over(hh_comp) asyvars stack percent ///
title("Percent Distribution of Children by Presence of Parents (All HDSS)") ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend() /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 
*/

***************************Gestion des couleurs*********************************
*Gérer les couleurs [Selon les remarques de Philippe]
/*
colorpalette, vertical n(10): ///
HCL blues / HCL greens / HCL oranges / HCL purples / HCL heat / HCL plasma

 colorpalette HCL blues,  n(10)

 : ///
 HCL blues / HCL greens / HCL oranges / HCL purples / HCL heat / HCL plasma 
*/
colorpalette HCL blues,  n(10) 
colorpalette HCL greens,  n(10) 
colorpalette HCL oranges,  n(10) 
colorpalette HCL purples,  n(20) 
colorpalette HCL heat,  n(10) 
colorpalette HCL plasma,  n(10) 

 
return list

********************************************************************************
/*
**Description de l'environnement familial de l'enfant  à la naissances suivant
**                 les différentes typologies
*/

/*
preserve 

expand 2
*370,500 observations created
replace hdss_2 = 6 in 370501/L
label def hdss_2 6"All HDSS", add
 */
 

*********************************** Typologie 1*********************************
*Composition familiale à la naissance selon la présence des parents biologiques

*English version
gr bar (count) wage2 if EventCode==2, over(hh_comp) over(hdss_2) stack percent ///
asyvars bar(1, color("73 150 95")) bar(2, color("0 81 0"))  ///
title("Distribution (%) of children by presence of parents and HDSS at the birth", size(medsmall)) ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend() blabel(bar, position(base) format(%5.2f)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 


*French version

gr bar (count) wage2 if EventCode==2, over(hh_comp) over(hdss_2) stack percent  legend(position(1)) ///
asyvars bar(1, color("73 150 95")) bar(2, color("0 81 0"))  ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend() blabel(bar, position(base) format(%5.2f)) /// 
 note("Source: données observatoires; calculs des auteurs.", span size(vsmall)) 


graph export "FM_birth_all_hdss.png", replace width(2000)
graph export "FM_birth_all_hdss.tif", replace width(2000)



*********************************** Typologie 2*********************************
ta hh_type_2 hdss_2 if EventCode==2,col
*by HDSS [à la naissance de l'enfant]
gr bar (count) wage2 if EventCode==2, over(hh_type_2) over(hdss_2)  stack percent ///
asyvars bar(1, color("255 191 128")) bar(2, color("82 0 144")) bar(3, color("126 101 164")) bar(4, color("243 239 252"))   ///
title("Children Living With Relatives by Type of Relative" "(Paternal and Maternal) and by HDSS (at birth)" ///
, size(medsmall))  ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend()  /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 
 
*French version
label define hh_type_2 0"Famille nucléaire" 1"Famille étendue patrilinéaire" 2"Famille étendue matrilinéaire" 3"Famille étendue bilatérale",modify
label val hh_type_2 hh_type_2

gr bar (count) wage2 if EventCode==2, over(hh_type_2) over(hdss_2)  stack percent legend(position(1) rows(1)) ///
asyvars bar(1, color("255 191 128")) bar(2, color("82 0 144")) bar(3, color("126 101 164")) bar(4, color("243 239 252"))   ///
ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
ytitle("") legend(size(vsmall))  /// 
note("Source: données observatoires; calculs des auteurs.", span size(vsmall)) 

graph save PandM_relatives_all_hdss_birth,replace

graph export "PandM_relatives_all_hdss_birth.png", replace width(2000)
graph export "PandM_relatives_all_hdss_birth.tif", replace width(2000)

*********************************** Typologie 3*********************************

ta hh_type3 hdss_2 if EventCode==2,col
colorpalette HCL oranges,  n(10) 

graph bar (count) wage2 if EventCode==2 ,over(hh_type3) over(hdss_2)  stack percent ///
asyvars bar(1, color("blue")) bar(2, color("ebblue")) bar(3, color("purple")) bar(4, color("red"))   ///
title("Percent Distribution of Children Living with Grandparents by HDSS(at birth)", ///
size(medsmall))  ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

*French version
label define lhh_type3 0"Aucun grand parent" 1"Grand-père uniquement" 2"Grand-mère uniquement" 3"Grand-père et Grand-mère" ///
, modify
label val hh_type3 lhh_type3

graph bar (count) wage2 if EventCode==2 ,over(hh_type3) over(hdss_2)  stack percent legend(position(1) rows(1))  ///
asyvars bar(1, color("blue")) bar(2, color("ebblue")) bar(3, color("purple")) bar(4, color("red"))   ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: données observatoires; calculs des auteurs.", span size(vsmall)) 

graph save  Gparents_all_hdss_birth,replace


graph export "Gparents_all_hdss_birth.png", replace width(2000)
graph export "Gparents_all_hdss_birth.tif", replace width(2000)

***
graph combine Gparents_all_hdss_birth.gph PandM_relatives_all_hdss_birth.gph

gr combine Gparents_all_hdss_birth.gph PandM_relatives_all_hdss_birth.gph, col(1) iscale(1)
/*
**Description de l'environnement familial de l'enfant durant ses 5 premières années 
**            de vie et suivant les différentes typologies
*/

*********************************** Typologie 1*********************************
ta hh_comp hdss_2 [iw = _t-_t0],col

graph bar (count) wage  [pw = _t-_t0] , over(hh_comp) over(hdss_2)  stack percent nofill ///
asyvars bar(1, color("black")) bar(2, color("73 150 95")) bar(3, color("232 244 231")) ///
bar(4, color("0 81 0"))  ///
title("Distribution (%) of person-year by Presence of Parents and HDSS") ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend()   /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

 *French version 
 label define lhh_comp 0"Enfants confiés" 1"Famille monoparentale-mère seule" 2"Famille monoparentale-père seul" 3"Famille biparentale",modify
 label val hh_comp lhh_comp 
 /*
 label define hhcomp 0"No parents" 1"Mother only" 2"Father only" ///
             3"Both parents", modify
*/
graph bar (count) wage  [pw = _t-_t0] , over(hh_comp) over(hdss_2)  stack percent nofill legend(position(1) rows(1))  ///
asyvars bar(1, color("black")) bar(2, color("73 150 95")) bar(3, color("232 244 231")) ///
bar(4, color("0 81 0"))  ///
title("") ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 
 
 
graph export "fparents_all_hdss.png", replace width(2000)
graph export "fparents_all_hdss.tif", replace width(2000)


*********************************** Typologie 2*********************************
ta hh_type_2 hdss_2 [iw = _t-_t0] ,col
ta hh_type_2 hdss_2 [iw = _t-_t0] if hh_comp==0&hh_type3==0,col

gr bar (count) wage  [pw = _t-_t0] , over(hh_type_2) over(hdss_2)  stack percent ///
title("Children Living With Relatives by Type of Relative" "(Paternal and Maternal) and by HDSS" , size(medsmall)) ///
asyvars bar(1, color("255 191 128")) bar(2, color("82 0 144")) bar(3, color("126 101 164")) bar(4, color("243 239 252"))   ///
ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" ///
100 "100%",labsize(vsmall)) ///
ytitle("") legend() /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

 
label define hh_type_2 0"Famille nucléaire" 1"Famille étendue patrilinéaire" 2"Famille étendue matrilinéaire" 3"Famille étendue bilatérale",modify
label val hh_type_2 hh_type_2


 *French version 
 label define lfhh_type_2 0"Enfants confiés" 1"Famille monoparentale-mère seule" 2"Famille monoparentale-père seul" 3"Famille biparentale",modify
 label val hh_comp lhh_comp 
	
 gr bar (count) wage  [pw = _t-_t0] , over(hh_type_2) over(hdss_2)  stack percent legend(position(1) rows(1)) ///
title("" , size(medsmall)) ///
asyvars bar(1, color("255 191 128")) bar(2, color("82 0 144")) bar(3, color("126 101 164")) bar(4, color("243 239 252"))   ///
ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" ///
100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 
 graph save PandM_relatives_all_hdss,replace
 
graph export "PandM_relatives_all_hdss.png", replace width(2000)
graph export "PandM_relatives_all_hdss.tif", replace width(2000)


*********************************** Typologie 3*********************************
ta hh_type3 hdss_2 [iw = _t-_t0] ,col

graph bar (count) wage  [pw = _t-_t0] ,over(hh_type3) over(hdss_2)  stack percent ///
asyvars bar(1, color("blue")) bar(2, color("ebblue")) bar(3, color("purple")) bar(4, color("red"))   ///
title("Percent Distribution of Children Living with Grandparents by HDSS", ///
size(medsmall))  ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

*french version
label define lhh_type3 0"Aucun grand parent" 1"Grand-père uniquement" 2"Grand-mère uniquement" 3"Grand-père et Grand-mère" ///
, modify
label val hh_type3 lhh_type3


graph bar (count) wage  [pw = _t-_t0] ,over(hh_type3) over(hdss_2)  stack percent legend(position(1) rows(1)) ///
asyvars bar(1, color("blue")) bar(2, color("ebblue")) bar(3, color("purple")) bar(4, color("red"))   ///
title("", size(medsmall))  ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///
 ytitle("") legend(size(vsmall)) /// 
 note("Source: HDSS data; authors’ calculations.", span size(vsmall)) 

graph save Gparents_all_hdss,replace
 
graph export "Gparents_all_hdss.png", replace width(2000)
graph export "Gparents_all_hdss.tif", replace width(2000)

graph combine PandM_relatives_all_hdss.gph Gparents_all_hdss.gph, rows(1)

grc1leg PandM_relatives_all_hdss.gph  Gparents_all_hdss.gph, row(1) ring(0) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))

save final_dataset_analysis_des_1,replace


XX
********************************************************************************
                        ** Dynamics analysis
********************************************************************************



********************************************************************************
****

use final_dataset_analysis_des_1,clear

label define yes_no 0"No" 1"Yes",modify
capture drop no_parent
gen no_parent = (hh_comp==0)
capture drop mother_only
gen mother_only = (hh_comp==1)
capture drop father_only
gen father_only =(hh_comp==2)
capture drop both_parent
gen both_parent = (hh_comp==3)


label val no_parent mother_only father_only both_parent yes_no
sort concat_IndividualId  EventDate EventCode
sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

stset EventDate, id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB)  scale(31557600000) entry(entry_d=1) exit(time exit_time_1)


foreach var of varlist no_parent mother_only father_only both_parent{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}



use final_dataset_analysis_des_1,clear

*Historical Living Arrangements of Children:
* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_parent
gen no_parent = (hh_comp==0)
capture drop mother_only
gen mother_only = (hh_comp==1)
capture drop father_only
gen father_only =(hh_comp==2)
capture drop both_parent
gen both_parent = (hh_comp==3)

label val no_parent mother_only father_only both_parent yes_no
sort concat_IndividualId  EventDate EventCode

ta mother_only 
*90823 
ta no_parent
*11,361 
ta father_only
*10,909
ta both_parent
*258,326 

sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc

sort concat_IndividualId EventDate
cap drop lastrecord
qui by concat_IndividualId: gen lastrecord=(_n==_N) 
tab lastrecord


*stset EventDate, id(concat_IndividualId) failure(lastrecord==1) time0(datebeg) scale(31557600000)


stset EventDate , id(concat_IndividualId) failure(lastrecord==1) exit(time .)  time0(datebeg) 



*** Create calendar time-varying covariate
forval num=1990/2019 {
display %20.0f clock("01Jan`num'","DMY")
}

cap drop calendar
stsplit calendar, at (946771200000 ///
978307200000 ///
1009843200000 ///
1041465600000 ///
1073001600000 ///
1104537600000 ///
1136073600000 ///
1167696000000 ///
1199232000000 ///
1230768000000 ///
1262304000000 ///
1293926400000 ///
1325462400000 ///
1356998400000 ///
1388534400000 ///
1420156800000 ///
1451692800000 ///
1483228800000 ///
1514764800000 ///
1546387200000 ///
1577923200000 ///
1609459200000 ///
1640995200000 ///
1672617600000 ///
1704153600000 ///
1735689600000 ///
1767225600000 ///
1798848000000 ///
1830384000000 ///
1861920000000)

sort concat_IndividualId EventDate EventCode
/*
cap drop calendar
stsplit calendar, at (10958 ///
11323 11688 12054 12419 ///
12784 13149 13515 13880 14245 14610 14976 15341 15706 16071 16437 16802 17167 ///
17532 17898 18263 18628 18993 19359 19724 20089 20454 20820 21185 21550)
*/


cap drop pyear 
recode calendar (946771200000=1990 "1990") ///
(978307200000=1991 "1991") ///
(1009843200000=1992 "1992") ///
(1041465600000=1993 "1993") ///
(1073001600000=1994 "1994") ///
(1104537600000=1995 "1995") ///
(1136073600000=1996 "1996") ///
(1167696000000=1997 "1997") ///
(1199232000000=1998 "1998") ///
(1230768000000=1999 "1999") ///
(1262304000000=2000 "2000") ///
(1293926400000=2001 "2001") ///
(1325462400000=2002 "2002") ///
(1356998400000=2003 "2003") ///
(1388534400000=2004 "2004") ///
(1420156800000=2005 "2005") ///
(1451692800000=2006 "2006") ///
(1483228800000=2007 "2007") ///
(1514764800000=2008 "2008") ///
(1546387200000=2009 "2009") ///
(1577923200000=2010 "2010") ///
(1609459200000=2011 "2011") ///
(1640995200000=2012 "2012") ///
(1672617600000=2013 "2013") ///
(1704153600000=2014 "2014") ///
(1735689600000=2015 "2015") ///
(1767225600000=2016 "2016") ///
(1798848000000=2017 "2017") ///
(1830384000000=2018 "2018") ///
(1861920000000=2019 "2019") (*=.), gen(pyear)

/*
recode calendar  (978307200000=11 "1990") (1009843200000=12 "1991") (1041465600000=13 "1992") ///
				(1073001600000=14 "1993") (1104537600000=15 "1994") (1136073600000=16 "1995") (1167696000000=17 "1996") ///
				(1199232000000=18 "1997") (1230768000000=19 "1998") (1262304000000=20 "1999") (1293926400000=21 "2000") ///
				(1325462400000=22 "2001") (1356998400000=23 "2002") (1388534400000=24 "2003") (1420156800000=25 "2004") ///
				(1451692800000=26 "2005") (1483228800000=27 "2006") (1514764800000=28 "2007") (1546387200000=29 "2008") ///
				(1577923200000=30 "2009") (1609459200000=31 "2010") (1640995200000=32 "2011") (1672617600000=33 "2012") ///
				(19359=34 "2013") (19724=35 "2014") (20089=36 "2015") (20454=37 "2016") ///
				(20820=38 "2017") (21185=39 "2018")(21550 =40 "2019")(*=.), gen(pyear)
*/
/*
foreach i in 10958 ///
11323 11688 12054 12419 ///
12784 13149 13515 13880 14245 14610 14976 15341 15706 16071 16437 16802 17167 ///
17532 17898 18263 18628 18993 19359 19724 20089 20454 20820 21185 21550{
replace EventCode=30 if EventDate==`i'
}
*/
foreach i in 946771200000 ///
978307200000 ///
1009843200000 ///
1041465600000 ///
1073001600000 ///
1104537600000 ///
1136073600000 ///
1167696000000 ///
1199232000000 ///
1230768000000 ///
1262304000000 ///
1293926400000 ///
1325462400000 ///
1356998400000 ///
1388534400000 ///
1420156800000 ///
1451692800000 ///
1483228800000 ///
1514764800000 ///
1546387200000 ///
1577923200000 ///
1609459200000 ///
1640995200000 ///
1672617600000 ///
1704153600000 ///
1735689600000 ///
1767225600000 ///
1798848000000 ///
1830384000000 ///
1861920000000 {
replace EventCode=30 if EventDate==`i'
}


*list concat_IndividualId DoB EventCode EventDate mother_only  pyear, sepby(concat_IndividualId)

/*
***correct lines with wrong value of mother_only and father_only no_parent both_parent
foreach var of varlist no_parent mother_only father_only both_parent{
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId: replace `var'=0 if `var'==1 & `var'[_n+1]==1 & ///
(pyear!=pyear[_n+1] & pyear!=.)
}
*/

stset EventDate , id(concat_IndividualId) failure(lastrecord==1) exit(time .) origin(time DoB) time0(datebeg) 


capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 

		
foreach var of varlist no_parent mother_only father_only both_parent{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}
save final_dataset_analysis_des_2,replace


use final_dataset_analysis_des_2,clear
drop if pyear==.

collapse (sum) no_parent_dur mother_only_dur father_only_dur both_parent_dur, by(hdss_2 pyear)

save final_dataset_analysis_des_3,replace

forval i=1/5 {
use final_dataset_analysis_des_3,clear
keep if hdss_2==`i'
gen percent1 = both_parent_dur / (both_parent_dur + mother_only_dur + father_only_dur + no_parent_dur) 
gen percent2 = (both_parent_dur+mother_only_dur)/ (both_parent_dur + ///
mother_only_dur + father_only_dur + no_parent_dur)
gen percent3 = (both_parent_dur + mother_only_dur + father_only_dur) / (both_parent_dur + ///
mother_only_dur + father_only_dur + no_parent_dur)
gen percent4 = 1
gen zero = 0 
save dataset_graph_`i',replace
}


*Farafenni
use dataset_graph_3,clear
twoway rarea zero percent1 pyear, color("0 81 0") /// 
    || rarea percent1 percent2 pyear, color("232 244 231") /// 
    || rarea percent2 percent3 pyear, color("73 150 95") /// 
	|| rarea percent3 percent4 pyear,color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
	legend(position(1) rows(1))  legend(size(vsmall)) ///
	 ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
       xla(1990(10)2010 2019) ytitle(Pourcentage cumulé) xtitle("Années") ///
		   title (Farafenni (1990 - 2019))
graph save hFarafenni,replace
	
	*||  pci 0 2001 1 2001, lcol(red) 

*Niakhar
use dataset_graph_4,clear
twoway rarea zero percent1 pyear, color("0 81 0") /// 
    || rarea percent1 percent2 pyear, color("232 244 231") /// 
    || rarea percent2 percent3 pyear, color("73 150 95") /// 
	|| rarea percent3 percent4 pyear,color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
	legend(position(1) rows(1))  legend(size(vsmall)) ///
	ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
       xla(1990(5)2015) ytitle(Pourcentage cumulé) xtitle("Années") ///
	   title (Niakhar (1990 - 2015))
graph save hNiakhar,replace


use dataset_graph_5,clear
twoway rarea zero percent1 pyear, color("0 81 0") /// 
    || rarea percent1 percent2 pyear, color("232 244 231") /// 
    || rarea percent2 percent3 pyear, color("73 150 95") /// 
	|| rarea percent3 percent4 pyear,color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
	legend(position(1) rows(1))  legend(size(vsmall)) ///
       xla(1990(10)2010 2017) ytitle(Pourcentage cumulé) xtitle("Années") ///
	  ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
	   title (Mlomp (1990 - 2017))
graph save hMlomp,replace


grc1leg hNiakhar.gph  hFarafenni.gph hMlomp.gph , legendfrom(hMlomp.gph) row(1) ///
 note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "hist_parents_all_hdss.png", replace width(2000)
graph export "hist_parents_hdss.tif", replace width(2000)



**by type of relatives
 ****************************************************************************
use final_dataset_analysis_des_2,clear

**Supprimer les villages introduits en 2002 à Farafenni

*Add to see the case of Farafenni
capture drop num_1
gen num_1  = length(IndividualId) 

replace num_1= 0 if hdss!="GM011"

replace IndividualId = "00" + IndividualId if num_1==7
replace IndividualId = "0" + IndividualId if num_1==8

capture drop village
gen village = substr(IndividualId,1,3)
replace village = "" if num_1==0

capture drop village2
destring village,gen(village2)
replace village2=0 if village2==.
capture drop new_border
gen new_border = EventCode==2 & village2>49

bys concat_IndividualId : egen c= max(new_border)

drop if c==1
*Historical Living Arrangements of Children:
* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_rel
gen no_rel = (hh_type_2==0)
capture drop pa_rel
gen pa_rel = (hh_type_2==1)
capture drop ma_rel
gen ma_rel =(hh_type_2==2)
capture drop bi_rel
gen bi_rel = (hh_type_2==3)

label val no_rel pa_rel ma_rel bi_rel yes_no
sort concat_IndividualId  EventDate EventCode

ta no_rel 
*165,231  
ta pa_rel
*121,616
ta ma_rel
*45,212 
ta bi_rel
*38,441 


		
foreach var of varlist no_rel pa_rel ma_rel bi_rel{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}
save final_dataset_analysis_des_2_rel,replace


use final_dataset_analysis_des_2_rel,clear
drop if pyear==.

collapse (sum) no_rel_dur pa_rel_dur ma_rel_dur bi_rel_dur, by(hdss_2 pyear)

save final_dataset_analysis_des_3_rel,replace

forval i=1/5 {
use final_dataset_analysis_des_3_rel,clear
keep if hdss_2==`i'
gen percent1 = bi_rel_dur / (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur) 
gen percent2 = (bi_rel_dur+pa_rel_dur)/ (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)
gen percent3 = (bi_rel_dur+pa_rel_dur + ma_rel_dur) / (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)
gen percent4 = 1
gen zero = 0 
save dataset_graphrel_`i',replace
}




*Farafenni
use dataset_graphrel_3,clear
twoway rarea zero percent1 pyear, color("243 239 252") /// 
    || rarea percent1 percent2 pyear, color("82 0 144") /// 
    || rarea percent2 percent3 pyear, color("126 101 164") /// 
	|| rarea percent3 percent4 pyear,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(1) rows(1))  legend(size(vsmall)) ///
	 ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
       xla(1990(10)2010 2019) ytitle(Pourcentage cumulé) xtitle("Année")  ///
		   title (Farafenni (1990 - 2019))
graph save relhFarafenni,replace

*||  pci 0 2001 1 2001, lcol(red) ///

*Farafenni
use dataset_graphrel_3,clear
twoway rarea zero percent1 pyear if pyear<2002, color("243 239 252") /// 
    || rarea percent1 percent2 pyear if pyear<2002, color("82 0 144") /// 
    || rarea percent2 percent3 pyear if pyear<2002, color("126 101 164") /// 
	|| rarea percent3 percent4 pyear if pyear<2002,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) ///
	legend(position(1) rows(1))  legend(size(vsmall)) /// 
	ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
       xla(1990(2)2000 2001) ytitle(Pourcentage cumulé) xtitle("Années")  ///
		   title (Farafenni (1990 - 2001))
graph save relhFarafenni_1990_2001,replace

	
*Farafenni
use dataset_graphrel_3,clear
twoway rarea zero percent1 pyear if pyear>2002, color("243 239 252") /// 
    || rarea percent1 percent2 pyear if pyear>2002, color("82 0 144") /// 
    || rarea percent2 percent3 pyear if pyear>2002, color("126 101 164") /// 
	|| rarea percent3 percent4 pyear if pyear>2002,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) ///
	legend(position(1) rows(1))  legend(size(vsmall)) ///
	ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
     xla(1990(5)2015 2019) ytitle(Pourcentage cumulé) xtitle("Année") ///
		   title (Farafenni (1990 - 2019))

	*||  pci 0 2001 1 2001, lcol(red) ///

*Niakhar
use dataset_graphrel_4,clear
twoway rarea zero percent1 pyear , color("243 239 252") /// 
    || rarea percent1 percent2 pyear, color("82 0 144") /// 
    || rarea percent2 percent3 pyear, color("126 101 164") /// 
	|| rarea percent3 percent4 pyear,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) ///
	legend(position(1) rows(1))  legend(size(vsmall)) ///
       xla(1990(5)2015) ytitle(Pourcentage cumulé) xtitle("Année") legend(size(vsmall)) ///
	  ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
		title (Niakhar (1990 - 2015)) 
		   
graph save relhNiakhar,replace

 
 
 *Mlomp
use dataset_graphrel_5,clear
twoway rarea zero percent1 pyear , color("243 239 252") /// 
    || rarea percent1 percent2 pyear, color("82 0 144") /// 
    || rarea percent2 percent3 pyear, color("126 101 164") /// 
	|| rarea percent3 percent4 pyear,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(1) rows(1))  legend(size(vsmall)) ///
       xla(1990(10)2010 2017) ytitle(Pourcentage cumulé) xtitle("Année") ///
	  ylabel(0"0%" .1 "10%" .2 "20%"  .3 "30%" .4 "40%" .5"50%" .6 "60%" .7 "70%" .8 "80%" .9 "90%" 1 "100%",labsize(vsmall)) ///
	  title (Mlomp (1990 - 2017)) 	   
graph save relhMlomp,replace

*net install grc1leg, from(http://www.stata.com/users/vwiggins)

grc1leg relhNiakhar.gph  relhMlomp.gph relhFarafenni.gph , legendfrom(relhMlomp.gph) row(1) ///
 note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "histrel_all_hdss.png", replace width(2000)
graph export "histrel_all_hdss.tif", replace width(2000)

 
 
 
 **by presence of grand parents
 ****************************************************************************
use final_dataset_analysis_des_2,clear

**Supprimer les villages introduits en 2002 à Farafenni
gen num_1  = length(IndividualId) 

replace num_1= 0 if hdss!="GM011"

replace IndividualId = "00" + IndividualId if num_1==7
replace IndividualId = "0" + IndividualId if num_1==8

capture drop village
gen village = substr(IndividualId,1,3)
replace village = "" if num_1==0

capture drop village2
destring village,gen(village2)
replace village2=0 if village2==.
capture drop new_border
gen new_border = EventCode==2 & village2>49

bys concat_IndividualId : egen c= max(new_border)

drop if c==1

*Historical Living Arrangements of Children:
* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_gp
gen no_gp = (hh_type3==0)
capture drop gf_pres
gen gf_pres = (hh_type3==1)
capture drop gm_pres
gen gm_pres =(hh_type3==2)
capture drop gmgf_rel
gen gmgf_rel = (hh_type3==3)

label val no_gp gf_pres gm_pres gmgf_rel yes_no
sort concat_IndividualId  EventDate EventCode

ta no_gp 
*186,922 
ta gf_pres
*18,660 
ta gm_pres
*88,412 
ta gmgf_rel
*76,506

	
foreach var of varlist no_gp gf_pres gm_pres gmgf_rel{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}
save final_dataset_analysis_des_2_gparents,replace


use final_dataset_analysis_des_2_gparents,clear
drop if pyear==.

collapse (sum) no_gp_dur gf_pres_dur gm_pres_dur gmgf_rel_dur, by(hdss_2 pyear)

save final_dataset_analysis_des_3_gparents,replace

forval i=1/5 {
use final_dataset_analysis_des_3_gparents,clear
keep if hdss_2==`i'
gen percent1 = gmgf_rel_dur / (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur) 
gen percent2 = (gmgf_rel_dur+gm_pres_dur)/ (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)
gen percent3 = (gmgf_rel_dur+gm_pres_dur + gf_pres_dur) / (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)
gen percent4 = 1
gen zero = 0 
save dataset_graphgparents_`i',replace
}


*Farafenni
use dataset_graphgparents_3,clear
twoway rarea zero percent1 pyear, color("red") /// 
    || rarea percent1 percent2 pyear, color("purple") /// 
    || rarea percent2 percent3 pyear, color("ebblue") /// 
	|| rarea percent3 percent4 pyear,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
       xla(1990(10)2010 2019)  yla(0 "0%" 0.2 "20%" .4 "40%" .6 "60%" .8"80%" 1"100%") ///
	    xtitle("Années") ///
		   title (Farafenni (1990 - 2019)) 
		   
graph save gphFarafenni,replace

	*||  pci 0 2001 1 2001, lcol(red) ///



*Niakhar
use dataset_graphgparents_4,clear
gen percent = gmgf_rel_dur / (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur) 

twoway rarea zero percent1 pyear, color("red") /// 
    || rarea percent1 percent2 pyear, color("purple") /// 
    || rarea percent2 percent3 pyear, color("ebblue") /// 
	|| rarea percent3 percent4 pyear,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
       xla(1990(5)2015)  yla(0 "0%" 0.2 "20%" .4 "40%" .6 "60%" .8"80%" 1"100%") ///
	   ytitle(Pourcentage cumulé) xtitle("Années") ///
		   title (Niakhar (1990 - 2015)) 
		   
graph save gphNiakhar,replace


 
*Mlomp
use dataset_graphgparents_5,clear
twoway rarea zero percent1 pyear, color("red") /// 
    || rarea percent1 percent2 pyear, color("purple") /// 
    || rarea percent2 percent3 pyear, color("ebblue") /// 
	|| rarea percent3 percent4 pyear,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) legend(position(1) rows(1))  legend(size(vsmall)) /// 
       xla(1990(10)2010 2017)  yla(0 "0%" 0.2 "20%" .4 "40%" .6 "60%" .8"80%" 1"100%") ///
	    xtitle("Années") ///
		   title (Mlomp (1990 - 2017)) 
		   
graph save gphMlomp,replace

grc1leg gphNiakhar.gph  gphMlomp.gph gphFarafenni.gph,  legendfrom(gphMlomp.gph) row(1) ///
 note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))



graph export "histgp_all_hdss.png", replace width(2000)
graph export "histgp_all_hdss.tif", replace width(2000)





********************************************************************************
 * By age group
********************************************************************************
use final_dataset_analysis_des_1,clear

**Supprimer les villages introduits en 2002 à Farafenni
gen num_1  = length(IndividualId) 

replace num_1= 0 if hdss!="GM011"

replace IndividualId = "00" + IndividualId if num_1==7
replace IndividualId = "0" + IndividualId if num_1==8

capture drop village
gen village = substr(IndividualId,1,3)
replace village = "" if num_1==0

capture drop village2
destring village,gen(village2)
replace village2=0 if village2==.
capture drop new_border
gen new_border = EventCode==2 & village2>49

bys concat_IndividualId : egen c= max(new_border)

drop if c==1

*Historical Living Arrangements of Children
* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_parent
gen no_parent = (hh_comp==0)
capture drop mother_only
gen mother_only = (hh_comp==1)
capture drop father_only
gen father_only =(hh_comp==2)
capture drop both_parent
gen both_parent = (hh_comp==3)

label val no_parent mother_only father_only both_parent yes_no
sort concat_IndividualId  EventDate EventCode

ta mother_only 
*90823 
ta no_parent
*11,361 
ta father_only
*10,909
ta both_parent
*258,326 
	  


sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %tc



*** TO CREATE AGE GROUP
*display %20.0f  1* 7 * 24 * 60 * 60 * 1000
*display %20.0f  1* 28 * 24 * 60 * 60 * 1000
display %20.0f  1* 365.25 
display %20.0f  2 * 365.25 
display %20.0f  3 * 365.25 
display %20.0f  4 * 365.25 
display %20.0f  5 * 365.25 

sort concat_IndividualId EventDate EventCode
cap drop lastrecord
qui by concat_IndividualId: gen lastrecord=_n==_N
*** ATTENTION: use time0(datebeg) systematically and split only for residence episode
stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) scale(31557600000) entry(entry_d=1) exit(time exit_time_1)

sort IndividualId EventDate EventCode
cap drop lastrecord
qui by IndividualId: gen lastrecord=_n==_N
*** ATTENTION: use time0(datebeg) systematically and split only for residence episode
stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB)scale(2629800000) entry(entry_d=1) exit(time exit_time_1)

capture drop group_age
stsplit double group_age if residence==1, at(0 1 2 3 4 5 6 7 8 9 10 11 12 13 ///
                                             14 15 16 17 18 19 20 21 22 23 24 ///
											 25 26 27 28 29 30 31 32 33 34 35 ///
											 36 37 38 39 40 41 42 43 44 45 46 ///
											 47 48 49 50 51 52 53 54 55 56 57 ///
											 58 59 60)
		
		
		
/*		
display %20.0f  1* 365.25 * 24 * 60 * 60 * 1000 
display %20.0f  2 * 365.25 * 24 * 60 * 60 * 1000 
display %20.0f  3 * 365.25 * 24 * 60 * 60 * 1000 
display %20.0f  4 * 365.25 * 24 * 60 * 60 * 1000 
display %20.0f  5 * 365.25 * 24 * 60 * 60 * 1000 






cap label drop group_age
label define group_age 0"0 yr" 1"1 yr" 2"2 yr" 3"3 yr" 4"4 yr" 4.99"5 yr", modify
label val group_age group_age

***correct lines with wrong value of mother_only and father_only no_parent both_parent
foreach var of varlist no_parent mother_only father_only both_parent{
sort concat_IndividualId EventDate EventCode
bys concat_IndividualId: replace `var'=0 if `var'==1 & `var'[_n+1]==1 & ///
(group_age!=group_age[_n+1] & group_age!=.)
}

	
capture drop group_age
stsplit group_age, at(0  1   2  3  4  4.99)
*replace group_age=group_age/100000 
sort concat_IndividualId EventDate EventCode
drop lastrecord
drop _*	
	*/
sort  concat_IndividualId EventDate EventCode
capture drop datebeg
bysort concat_IndividualId (EventDate) : gen double datebeg=cond(_n==1, DoB, EventDate[_n-1])
format datebeg %td

capture drop lastrecord
sort hdss concat_IndividualId EventDate EventCode
bys concat_IndividualId: gen lastrecord=(_n==_N) 

save final_dataset_analysis_des_gr_age,replace

use final_dataset_analysis_des_gr_age,clear


foreach var of varlist no_parent mother_only father_only both_parent{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}

save final_dataset_analysis_des_gr_2,replace

use final_dataset_analysis_des_gr_2,clear
drop if group_age==.
collapse (sum) no_parent_dur mother_only_dur father_only_dur both_parent_dur, by(hdss_2 group_age)

save final_dataset_analysis_des_gr_3,replace

forval i=1/5 {
use final_dataset_analysis_des_gr_3,clear
keep if hdss_2==`i'
gen percent1 = both_parent_dur / (both_parent_dur + mother_only_dur + father_only_dur + no_parent_dur) 
gen percent2 = (both_parent_dur+mother_only_dur)/ (both_parent_dur + ///
mother_only_dur + father_only_dur + no_parent_dur)
gen percent3 = (both_parent_dur + mother_only_dur + father_only_dur) / (both_parent_dur + ///
mother_only_dur + father_only_dur + no_parent_dur)
gen percent4 = 1
gen zero = 0 
save dataset_graph_gr`i',replace
}

*Ouagadougou
use dataset_graph_gr1,clear
twoway rarea zero percent1 group_age, color("0 81 0") /// 
    || rarea percent1 percent2 group_age, color("232 244 231")  /// 
    || rarea percent2 percent3 group_age, color("73 150 95") /// 
	|| rarea percent3 percent4 group_age, color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
     xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
	  title("Ouagadougou", size(medsmall)) 
graph save Ouaga,replace
	   

*Nanoro
use dataset_graph_gr2,clear
twoway rarea zero percent1 group_age, color("0 81 0") /// 
    || rarea percent1 percent2 group_age , color("232 244 231") /// 
    || rarea percent2 percent3 group_age , color("73 150 95") /// 
	|| rarea percent3 percent4 group_age , color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
       xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
	  title("Nanoro", size(medsmall)) 
graph save Nanoro,replace
	   
	  

*Farafenni
use dataset_graph_gr3,clear
twoway rarea zero percent1 group_age , color("0 81 0")  /// 
    || rarea percent1 percent2 group_age , color("232 244 231") /// 
    || rarea percent2 percent3 group_age , color("73 150 95") /// 
	|| rarea percent3 percent4 group_age , color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
        xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
	  title("Farafenni", size(medsmall)) 
graph save Farafenni,replace
	  
	

*Niakhar
use dataset_graph_gr4,clear
twoway rarea zero percent1 group_age , color("0 81 0") /// 
    || rarea percent1 percent2 group_age , color("232 244 231") /// 
    || rarea percent2 percent3 group_age , color("73 150 95") /// 
	|| rarea percent3 percent4 group_age , color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
        xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
	  title("Niakhar", size(medsmall)) 
graph save Niakhar,replace
	  

*Mlomp
use dataset_graph_gr5,clear
twoway rarea  zero percent1 group_age, color("0 81 0") /// 
    || rarea percent1 percent2 group_age , color("232 244 231") /// 
    || rarea percent2 percent3 group_age , color("73 150 95") /// 
	|| rarea percent3 percent4 group_age , color("black") /// 
    ||, legend(order(4 "Enfants confiés" 3 "Famille monoparentale-père seul" ///
	2 "Famille monoparentale-mère seule" 1 "Famille biparentale")) /// 
	 legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
	  title("Mlomp", size(medsmall)) 
graph save Mlomp,replace

	  

grc1leg Ouaga.gph  Nanoro.gph Farafenni.gph Niakhar.gph Mlomp.gph, legendfrom(Mlomp.gph) row(1)  ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "presenp_age_hdss.png", replace width(2000)
graph export "presenp_age_hdss.tif", replace width(2000)


* by relatives
use final_dataset_analysis_des_gr_age,clear



* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_rel
gen no_rel = (hh_type_2==0)
capture drop pa_rel
gen pa_rel = (hh_type_2==1)
capture drop ma_rel
gen ma_rel =(hh_type_2==2)
capture drop bi_rel
gen bi_rel = (hh_type_2==3)

label val no_rel pa_rel ma_rel bi_rel yes_no
sort concat_IndividualId  EventDate EventCode

ta no_rel 
*165,231  
ta pa_rel
*121,616
ta ma_rel
*45,212 
ta bi_rel
*38,441 

stset EventDate , id(concat_IndividualId) failure(lastrecord==1) ///
		time0(datebeg) origin(time DoB) scale(2629800000) entry(entry_d=1) exit(time exit_time_1)

		
foreach var of varlist no_rel pa_rel ma_rel bi_rel{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}
save final_dataset_analysis_des_2_rel_age,replace


use final_dataset_analysis_des_2_rel_age,clear
drop if group_age==.


collapse (sum) no_rel_dur pa_rel_dur ma_rel_dur bi_rel_dur, by(hdss_2 group_age)

save final_dataset_analysis_des_3_rel_age,replace

forval i=1/5 {
use final_dataset_analysis_des_3_rel_age,clear
keep if hdss_2==`i'
gen percent1 = bi_rel_dur / (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur) 
gen percent2 = (bi_rel_dur+pa_rel_dur)/ (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)
gen percent3 = (bi_rel_dur+pa_rel_dur + ma_rel_dur) / (no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)
gen percent4 = 1
gen zero = 0 
save dataset_graphrel_age_`i',replace
}




use dataset_graphrel_age_1,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Ouagadougou", size(medsmall)) 
graph save relhOuaga_age,replace		   



use dataset_graphrel_age_2,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Nanoro", size(medsmall)) 
graph save relhNanoro_age,replace		   



*Farafenni
use dataset_graphrel_age_3,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" ///
	2 "Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Farafenni", size(medsmall)) 
graph save relhFarafenni_age,replace
	


*Niakhar
use dataset_graphrel_age_4,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "Famille nucléaire" 3 "Famille étendue matrilinéaire" 2 ///
	"Famille étendue patrilinéaire" 1 "Famille étendue bilatérale")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Niakhar", size(medsmall)) 
graph save relhNiakhar_age,replace
		   

*Mlomp
use dataset_graphrel_age_5,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "No relatives" 3 "Maternal relatives" 2 "Paternal relatives" 1 "bilateral relatives")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Mlomp", size(medsmall)) 
graph save relhMlomp_age,replace		   

 
grc1leg relhOuaga_age.gph  relhNanoro_age.gph relhFarafenni_age.gph ///
 relhNiakhar_age.gph relhMlomp_age.gph, legendfrom(relhMlomp_age.gph) row(1)  ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))

graph export "histrel_allage_hdss.png", replace width(2000)
graph export "histrel_allage_hdss.tif", replace width(2000)




 
****************************************************************************
**by presence of grand parents
****************************************************************************
 use final_dataset_analysis_des_gr_age,clear

*Historical Living Arrangements of Children:
* Création des variables
label define yes_no 0"No" 1"Yes",modify
capture drop no_gp
gen no_gp = (hh_type3==0)
capture drop gf_pres
gen gf_pres = (hh_type3==1)
capture drop gm_pres
gen gm_pres =(hh_type3==2)
capture drop gmgf_rel
gen gmgf_rel = (hh_type3==3)

label val no_gp gf_pres gm_pres gmgf_rel yes_no
sort concat_IndividualId  EventDate EventCode

ta no_gp 
*186,922 
ta gf_pres
*18,660 
ta gm_pres
*88,412 
ta gmgf_rel
*76,506

	
foreach var of varlist no_gp gf_pres gm_pres gmgf_rel{
sort concat_IndividualId EventDate EventCode
 bys concat_IndividualId : gen `var'_dur = _t - _t0 if `var'==1
 bys concat_IndividualId : replace `var'_dur = 0 if `var'_dur ==.
}

save final_dataset_analysis_des_2_gparents_age,replace

use final_dataset_analysis_des_2_gparents_age,clear
drop if group_age==.


collapse (sum) no_gp_dur gf_pres_dur gm_pres_dur gmgf_rel_dur, by(hdss_2 group_age)

save final_dataset_analysis_des_3_gparents_age,replace


forval i=1/5 {
use final_dataset_analysis_des_3_gparents_age,clear
keep if hdss_2==`i'
gen percent1 = gmgf_rel_dur / (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur) 
gen percent2 = (gmgf_rel_dur+gm_pres_dur)/ (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)
gen percent3 = (gmgf_rel_dur+gm_pres_dur + gf_pres_dur) / (no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)
gen percent4 = 1
gen zero = 0 
save dataset_gparents_age_`i',replace
}


* Ouagadougou
use dataset_gparents_age_1,clear
twoway rarea zero percent1 group_age, color("red") /// 
    || rarea percent1 percent2 group_age, color("purple") /// 
    || rarea percent2 percent3 group_age, color("ebblue") /// 
	|| rarea percent3 percent4 group_age,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
		   title("Ouagadougou", size(medsmall)) 
graph save gphOuaga,replace


*Nanoro
use dataset_gparents_age_2,clear
twoway rarea zero percent1 group_age, color("red") /// 
    || rarea percent1 percent2 group_age, color("purple") /// 
    || rarea percent2 percent3 group_age, color("ebblue") /// 
	|| rarea percent3 percent4 group_age,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
		   title("Nanoro", size(medsmall)) 
graph save gphNanoro,replace



*Farafenni
use dataset_gparents_age_3,clear
twoway rarea zero percent1 group_age, color("red") /// 
    || rarea percent1 percent2 group_age, color("purple") /// 
    || rarea percent2 percent3 group_age, color("ebblue") /// 
	|| rarea percent3 percent4 group_age,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
		   title("Farafenni", size(medsmall)) 
graph save gphFarafenni,replace
	

*Niakhar
use dataset_gparents_age_4,clear
twoway rarea zero percent1 group_age, color("red") /// 
    || rarea percent1 percent2 group_age, color("purple") /// 
    || rarea percent2 percent3 group_age, color("ebblue") /// 
	|| rarea percent3 percent4 group_age,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
		   title("Niakhar", size(medsmall)) 
graph save gphNiakhar,replace


*Mlomp
use dataset_gparents_age_5,clear
twoway rarea zero percent1 group_age, color("red") /// 
    || rarea percent1 percent2 group_age, color("purple") /// 
    || rarea percent2 percent3 group_age, color("ebblue") /// 
	|| rarea percent3 percent4 group_age,color("blue") /// 
    ||, legend(order(4 "Aucun grand parent" 3 "Grand-père uniquement" ///
	2 "Grand-mère uniquement" 1 "Grand-père et Grand-mère") ///
	size(vsmall)) 	legend(position(6) rows(1))  legend(size(vsmall)) /// 
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") ///
		   title("Mlomp", size(medsmall)) 
graph save gphMlomp,replace



grc1leg  gphOuaga.gph gphNanoro.gph gphFarafenni.gph gphNiakhar.gph gphMlomp.gph, legendfrom(gphMlomp.gph) row(1) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "histgp_allage_hdss.png", replace width(2000)
graph export "histgp_allage_hdss.tif", replace width(2000)


**Evolution suivant l'âge de l'enfant  de la présence avunculaire
use dataset_graphrel_age_5,clear
twoway rarea zero percent1 group_age, color("243 239 252") /// 
    || rarea percent1 percent2 group_age, color("82 0 144") /// 
    || rarea percent2 percent3 group_age, color("126 101 164") /// 
	|| rarea percent3 percent4 group_age,color("255 191 128") /// 
    ||, legend(order(4 "No relatives" 3 "Maternal relatives" 2 "Paternal relatives" 1 "bilateral relatives")) /// 
	legend(position(6) rows(1))  legend(size(vsmall)) ///
      xtitle(age (mois)) xlab(0(12)60) ylab(0"0%" .2"20%" .4"40%" .6"60%" .8"80%" 1"100%") /// 
	    title("Mlomp", size(medsmall)) 
graph save relhMlomp_age,replace		   


use dataset_graphrel_age_2,clear
append using dataset_graphrel_age_3
append using dataset_graphrel_age_4
append using dataset_graphrel_age_5

capture drop pres_rel
gen pres_rel = (pa_rel_dur + ma_rel_dur + bi_rel_dur)/(no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)

separate pres_rel, by(hdss_2) veryshortlabel

graph twoway scatter pres_rel? group_age, color(black black black black) ///
ylab( .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%") ///
xtitle(age (mois)) xlab(0(6)60) ///
legend(pos(12) row(1))  legend(size(small)) ///
yscale(r(.3 .8)) ///
msymbol(smplus X o s) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))

graph save grelative_all,replace

graph export "grelative_all.png", replace width(2000)
graph export "grelative_all.tif", replace width(2000)


title("Distribution (%) of children by presence of parents and HDSS at the birth", size(medsmall)) ///
 ylabel(0 "0%" 10 "10%" 20 "20%"  30"30%" 40 "40%" 50 "50%" 60 "60%" 70 "70%" 80 "80%" 90 "90%" 100 "100%",labsize(vsmall)) ///

**Patrilinéaire
use dataset_graphrel_age_2,clear
append using dataset_graphrel_age_3
append using dataset_graphrel_age_4
append using dataset_graphrel_age_5

capture drop pres_relp
gen pres_relp = (pa_rel_dur)/(no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)

separate pres_relp, by(hdss_2) veryshortlabel

graph twoway scatter pres_relp? group_age, color(black black black black) ///
ylab( .1"10%" .2"20%" .3"30%" .4"40%" .5"50%" .6"60%",labsize(vsmall)) ///
xtitle(age (mois)) xlab(0(6)60,labsize(vsmall)) ///
yti("`: variable label length'") ///
title("Présence avunculaire (patrilinéaire)", size(msmall)) ///
legend(pos(12) row(1))  legend(size(small)) ///
yscale(r(0.1 .6)) ///
msymbol(smplus X o s) msize(small small small small)

graph save prelative_all,replace

graph export "prelative_all.png", replace width(2000)
graph export "prelative_all.tif", replace width(2000)


**Matrilinéaire
use dataset_graphrel_age_2,clear
append using dataset_graphrel_age_3
append using dataset_graphrel_age_4
append using dataset_graphrel_age_5

capture drop pres_relm
gen pres_relm = (ma_rel_dur)/(no_rel_dur + pa_rel_dur + ma_rel_dur + bi_rel_dur)

separate pres_relm, by(hdss_2) veryshortlabel

graph twoway scatter pres_relm? group_age, color(black black black black) ///
ylab(0"0%" 0.05"5%" .1"10%" .15"15%" .2"20%" .25"25%" .3"30%" .35"35%" .4"40%",labsize(vsmall)) ///
xtitle(age (mois)) xlab(0(6)60,labsize(vsmall)) ///
title("Présence avunculaire (matrilinéaire)", size(msmall)) ///
legend(pos(12) row(1))  legend(size(small)) ///
yscale(r(0 .4)) ///
msymbol(smplus X o s) msize(small small small small)

graph save mrelative_all,replace

graph export "mrelative_all.png", replace width(2000)
graph export "mrelative_all.tif", replace width(2000)

grc1leg   prelative_all.gph mrelative_all.gph, legendfrom(mrelative_all.gph) row(1) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))

graph export "m_p_relative_all.png", replace width(2000)
graph export "m_p_relative_all.tif", replace width(2000)


**Evolution suivant l'âge de l'enfant  de la présence des grands parents

use dataset_gparents_age_2,clear
append using dataset_gparents_age_3
append using dataset_gparents_age_4
append using dataset_gparents_age_5



*All
capture drop pres_gp
gen pres_gp = (gf_pres_dur + gm_pres_dur + gmgf_rel_dur)/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate pres_gp, by(hdss_2) veryshortlabel

graph twoway scatter pres_gp? group_age, color(gray gray gray gray) ///
ylab( .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%") ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(small)) ///
yscale(r(.3 .8)) ///
msymbol(smplus X o s) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "gparent.png", replace width(2000)
graph export "gparent.tif", replace width(2000)




*All
capture drop pres_gp
gen pres_gp = (gf_pres_dur + gm_pres_dur + gmgf_rel_dur)/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate pres_gp, by(hdss_2) veryshortlabel

graph twoway scatter pres_gp? group_age, color(gray gray gray gray) ///
ylab( .3"30%" .4"40%" .5"50%" .6"60%" .7"70%" .8"80%") ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(small)) ///
yscale(r(.3 .8)) ///
msymbol(smplus X o s) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


graph export "gparent.png", replace width(2000)
graph export "gparent.tif", replace width(2000)

use dataset_gparents_age_1,clear
capture drop pres_gp
gen pres_gp = (gf_pres_dur + gm_pres_dur + gmgf_rel_dur)/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate pres_gp, by(hdss_2) veryshortlabel

graph twoway scatter pres_gp? group_age,  color(gray gray gray gray) ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(small)) ///
msymbol(smplus X o s) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))






* Grand mothers
use dataset_gparents_age_2,clear
append using dataset_gparents_age_3
append using dataset_gparents_age_4
append using dataset_gparents_age_5

*All
capture drop lpres_gpm
gen lpres_gpm = (gm_pres_dur )/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate lpres_gpm, by(hdss_2) veryshortlabel

graph twoway scatter lpres_gpm? group_age, color(gray gray gray gray) ///
ylab( 0.05"5%" .1"10%" .2"20%" .3"30%" .4"40%") ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(vsmall)) ///
yscale(r(0.05 .4)) ///
msymbol(smplus X o s) ///
note("Source: données des observatoires; calcul des auteurs.", span size(vsmall))


* Grand fathers
use dataset_gparents_age_2,clear
append using dataset_gparents_age_3
append using dataset_gparents_age_4
append using dataset_gparents_age_5

*All
capture drop lpres_gpf
gen lpres_gpf = (gf_pres_dur )/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate lpres_gpf, by(hdss_2) veryshortlabel

graph twoway scatter lpres_gpf? group_age, color(gray gray gray gray) ///
ylab( 0.03"3%" 0.04"4%" 0.05"5%" 0.06"6%" 0.07"7%" 0.08"8%" 0.09"9%" 0.1"10%") ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(vsmall)) ///
yscale(r(0.03 .1)) ///
msymbol(smplus X o s)


* Grand fathers and grand mothers
use dataset_gparents_age_2,clear
append using dataset_gparents_age_3
append using dataset_gparents_age_4
append using dataset_gparents_age_5

*All
capture drop lpres_gmgf
gen lpres_gmgf = (gmgf_rel_dur )/(no_gp_dur + gf_pres_dur + gm_pres_dur + gmgf_rel_dur)

separate lpres_gmgf, by(hdss_2) veryshortlabel

graph twoway scatter lpres_gmgf? group_age, color(gray gray gray gray) ///
ylab( .1"10%" .2"20%" .3"30%" .4"40%") ///
xtitle(age (mois)) xlab(0(6)60) ///
yti("`: variable label length'") ///
legend(pos(12) row(1))  legend(size(vsmall)) ///
yscale(r(0 .4)) ///
msymbol(smplus X o s)
