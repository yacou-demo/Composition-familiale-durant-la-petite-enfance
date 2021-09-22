use residency_final_5HDSS.dta,clear
rename IndividualID IndividualId

* Creation de la variable residence
capture drop residence
gen residence=.

sort IndividualId EventDate EventCode
	*list IndividualId DoB EventCode datebeg EventDate, sepby(IndividualId)

***Enumarated
qui by IndividualId: replace residence=0 if EventCode==1
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)

***Exit
replace residence=1 if residence==.& EventCode==5
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
***Death
replace residence=1 if residence==.& EventCode==7
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
***Birth
replace residence=0 if residence==.& EventCode==2
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)

***Entry
	*Case with ENT preceded by EXT and less than 6 months
	qui by IndividualId: replace residence=1 if residence==. & ///
	(EventCode==6 & EventCode[_n-1]==5 & EventDate-EventDate[_n-1]<=15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
	
	*Case with ENT preceded by EXT and more than 6 months
	qui by IndividualId: replace residence=0 if residence==. & ///
	(EventCode==6 & EventCode[_n-1]==5 & EventDate-EventDate[_n-1]>15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)

	*Case with ENT preceded by OMG and less than 6 months duration
	qui by IndividualId: replace residence=1 if residence==. & ///
	(EventCode==6 & EventCode[_n-1]==4 & EventDate-EventDate[_n-1]<=15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)

***In Migration
	
	*Cases with IMG preceded by OMG less than 6 months
	qui by IndividualId: replace residence=1 if residence==. & ///
	(EventCode==3 & EventCode[_n-1]==4 & EventDate-EventDate[_n-1]<=15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
	
	*Cases with IMG preceded by OMG  more than 6 months
	qui by IndividualId: replace residence=0 if residence==. & ///
	(EventCode==3 & EventCode[_n-1]==4 & EventDate-EventDate[_n-1]>15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
	
	***Entry by IMG
	qui by IndividualId: replace residence=0 if residence==. & EventCode==3 & _n==1

***Out migration
qui by IndividualId: replace residence=1 if residence==. & EventCode==4
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
	
	*Cases with OMG precede by IMG, but less than 6 months of residence
qui by IndividualId: replace residence=0 if residence==1 & ///
	(EventCode==4 & EventCode[_n-1]==3 & EventDate-EventDate[_n-1]<=15778800000)
		*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)

***For last record: OBE in the HDSS
qui by IndividualId: replace residence=1 if EventCode==9 & _n==_N

tab EventCode residence, miss

*Identification of remaining cases
egen misresidence=max(residence==.), by(IndividualId)
	*list IndividualId DoB EventCode datebeg EventDate residence, sepby(IndividualId)
	*If few cases with inconsitencies, delete observations
	drop if residence==.
	*...or delete cases with inconsistencies
	cap drop misresidence. 

save residency_final_5HDSS_res,replace