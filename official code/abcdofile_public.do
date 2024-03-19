*All tables for Aker, Ksoll and Lybbert*

#delimit;
clear;
capture clear matrix;
set more on;
set mem 500m;
set matsize 5000;
set maxvar 3200;

#delimit cr

set more off

******************;
*TABLE 1: PANEL A*;
******************;
*
use "$df/ABChousehold.dta", clear

//Define baseline sample
keep if year==2009
gen N=_n

//If drought variable is equal to ".", then this means the household did not experience drought

foreach i in age hhhead eth_hausa hhmem_no edchild_percent assets drought cellphone accesscellphone usecellphone makecall receivecall{
	bys abc: su `i'
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "$df/Table1_PanelA.xls", dec(2) append excel ctitle ("`var'")	nocons
	}

clear

***********************************;
*TABLE 1, PANEL B: TEACHER QUALITY*;
***********************************;

use "$df/ABCtestscore.dta", clear

bys codev: keep if _n==1
keep codev
merge 1:m codev using "$df/ABCteacher.dta"

tab _m
drop if _m==2

foreach i in levelno teacherage femaleteacher local{
	bys abc: su `i' 
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "$df/Table1_PanelB.xls", dec(2) append excel ctitle ("`var'")	nocons
	}
clear

***********;
*FIGURE 3*;
**********;
*
use "$df/ABCtestscore.dta", clear

//5 and 17-month results

foreach i in write math {
	ttest `i' if round==2|round==4, by(abc)
	bys abc: su `i' if round==2|round==4
}

foreach i in write math {
	reg `i' abc cohort2009 age female dosso if round==2|round==4, robust cluster(codev)
	areg `i' abc cohort2009 age female if round==2|round==4, abs(avcode) robust cluster(codev) 	
}

*********************************************;
*TABLE 2: COMPARISON OF TEST SCORES BY ROUND*;
*********************************************;

use "$df/ABCtestscore.dta", replace
global charlist "writez1 mathz1"

foreach i of global charlist {
	bys abc: su `i'
	xi: reg `i' abc i.avc, cluster(codev)
	outreg2 abc using "$df/Table2.xls", dec(2) append excel ctitle ("`var'") 	nocons	
	}

clear


********************************************;
*TABLE 3:  DIFFERENCE IN DIFFERENCE*;
********************************************;

use "$df/ABCtestscore.dta", clear

//Keep the baseline and six-month rounds

keep if round==1|round==2|round==4

foreach i in writezscore mathzscore{
	reg `i' abcpost abc post, robust cluster(codev)
	outreg2 abcpost abc post  using "$df/table3.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	reg `i' abcpost abc post cohort2009 female age dosso , robust cluster(codev)
	outreg2 abcpost abc  post cohort2009 female age dosso using "$df/table3.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	areg `i' abcpost abc post cohort2009 female age , abs(avcode) robust cluster(codev)
	outreg2 abcpost abc post cohort2009 female age using "$df/table3.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	areg `i' abcpost post female age, abs(codev) robust cluster(codev)
	outreg2 abcpost post female age using "$df/table3.xls", append excel nocons ctitle("`i'") dec(3)
	}

	
************************************************************************;
*TABLE 4:  HETEROGENEOUS RESULTS BY REGION AND STUDENT CHARACTERISTICS*;
************************************************************************;

use "$df/ABCtestscore.dta", clear

//Keep the baseline and six-month rounds

keep if round==1|round==2|round==4

*************************;
*Columns 1 and 4: REGION*;
*************************;

* initialize outreg
*		reg writezscore abc abcpost, robust cluster(codev)
*	      	outreg2 abcpost using "$df/table4.xls", replace excel nocons

//Generate necessary variables
	
	capture drop region regionpost regionabc abcregionpost
	gen region=dosso==1
	gen regionpost=region*post
	gen regionabc=region*abc
	gen abcregionpost=regionabc*post
	
foreach i in writezscore mathzscore {
	areg `i' abc post abcpost cohort2009 female age , abs(avcode) robust cluster(codev)
	outreg2 abcpost  using "$df/table4.xls", append excel nocons ctitle("`i'")  dec(3)
	sleep 1000

	reg `i' abcpost  abcregionpost abc region post regionpost regionabc cohort2009 female age , robust cluster(codev)  
	outreg2 abcregionpost abcpost regionpost regionabc using "$df/table4.xls", append excel nocons ctitle("`i'") dec(3)
	test abcregionpost+abcpost=0
		
	sleep 1000

************************;
*Columns 2 and 5 GENDER*;
************************;

	areg `i' abcpost abcfemalepost abc female post  femalepost femaleabc cohort2009 age , abs(avcode) robust cluster(codev) 
	outreg2 abcfemalepost abcpost femalepost femaleabc using "$df/table4.xls", append excel nocons ctitle("`i'")  dec(3)
		test abcfemalepost+abcpost=0

	sleep 1000

*********************;
*Columns 3 and 6 AGE*;
*********************;

* Note the number of observations drops here, because we exclude persons with missing observations, who generally receive an imputed age

	areg `i' abcpost abcyoungpost abc young post youngpost youngabc cohort2009 female age , abs(avcode) robust cluster(codev)
	outreg2 abcyoungpost abcpost youngpost youngabc using "$df/table4.xls", append excel nocons ctitle("`i'")  dec(3)
	sleep 1000
	test abcyoungpost+abcpost=0
	}
clear


***********************;
*FIGURE:  Distribution*;
***********************;
	
use "$df/ABCtestscore.dta", clear

//Keep if 6-month results for both cohorts

keep if timesince==2|timesince==4
gen line=_n

foreach i in math write{
forvalues j=1/7 {
gen level`j'`i'=`i'>=`j' & `i'!=.
}
}
gen xb1=.
gen xb2=.
gen xb3=.

*math
local i2=0
foreach i in math write{
forvalues j=1/7 {
 capture drop LHS
 gen LHS=level`j'`i'
quietly xi: logit LHS abc cohort2009 timesince female i.avcode if  (timesince==2|timesince==4), robust cluster(codev) or
 outreg2 abc cohort2009 timesince female using "$df/figure4.xls", append excel nocons eform ctitle("`i' level `j'")
sleep 1000

* here save beta and se. Then gen upper as beta + 2*se. Then drop all other variables, and generate scatterplot. Overlay range plot.
replace xb1=_b[abc]-1.68*_se[abc] if line==`j' + `i2'*10
replace xb2=_b[abc] if line==`j' + `i2'*10
replace xb3=_b[abc]+1.68*_se[abc] if line==`j' + `i2'*10

drop LHS
}
local i2=`i2'+1
}

replace xb1=exp(xb1)
replace xb2=exp(xb2)
replace xb3=exp(xb3)

sleep 2000
edit xb* line
clear


*****************************;
*TABLE 5: PERSISTENT EFFECTS*;
*****************************;

use "$df/ABCtestscore.dta", clear

foreach i in writezsc mathzsc{
	areg `i'  abcpost post abc abcpost6m post6m cohort2009 female age, abs(avcode) robust cluster(codev)
	outreg2 abcpost post abc abcpost6m post6m cohort2009 female age using "$df/table5.xls", append excel nocons ctitle("`i'") dec(3)
	test abcpost=abcpost6m
	sleep 500
	}
clear

*****************************************************;
*TABLE 6: Student and Teacher ATTENDANCE*;
*****************************************************;

use "$df/ABCtestscore.dta", clear

merge m:1 codev class year using "$df/ABCteacher.dta"
drop if _m==2


rename levelno level
su level
gen levelabc=abc*(level-r(mean))

********************;
*TABLE 6, PANEL A*
********************;
bys codev class round year : gen first=_n

bys codev class round year: egen htotaldays=mean(totaldays)
bys codev class round year: egen htotaldays12=mean(totaldays12)
bys codev class round year: egen htotaldays34=mean(totaldays34)

gen teacherdaysy1= htotaldays if first==1 & time==2
bys abc: su teacherdaysy1
gen teacherdaysy1m12= htotaldays12 if first==1 & time==2
gen teacherdaysy1m34= htotaldays34 if first==1 & time==2
gen teacherdaysy2= htotaldays if first==1 & time==4
bys abc: su teacherdaysy2

foreach i in teacherdaysy1 teacherdaysy1m12 teacherdaysy1m34{
	areg `i' abc, abs(avcode) robust cluster(codev)
	outreg2 abc using "$df/table6a.xls", append excel nocons ctitle("`i'")  dec(3)
	}

*************************;
*TABLE 6, PANELS B AND C*;
*************************;

gen percentattendy1= percentattend if  time==2
bys abc: su percentattendy1
gen percentattendy1m12= percentattend12 if  time==2
gen percentattendy1m34= percentattend34 if  time==2
gen percentattendy2= percentattend if time==4
bys abc: su percentattendy2

foreach i in percentattendy1 percentattendy1m12 percentattendy1m34 percentattendy2{
	areg `i' abc, abs(avcode) robust cluster(codev)
	outreg2 abc using "$df/table6bc.xls", append excel nocons ctitle("`i'")  dec(3)
	}
clear

*************************************************;
* TABLE 7: Effort and Teacher Level of Education*;
*************************************************;

use "$df/ABCteacher.dta", clear

*Keep information on teachers, before teachers were aware of whether they were ABC or not
keep if (cohort==2009&year==2009) | (cohort==2010&year==2010)
save "$df/tempteacher.dta", replace

use "$df/ABCtestscore.dta", clear

merge m:1 codev class using "$df/tempteacher.dta"
drop if _m==2

keep if time==1|time==2

rename levelno level
su level, det
gen levelabc=abc*(level-r(mean))

gen levelpost=post*(level-r(mean))
gen abclevelpost=abc*levelpost

su level, det
gen highlevel=level>r(mean) if level!=.
gen highlevelpost=highlevel*post
gen highlevelabc=abc*highlevel
gen abchighlevelpost=highlevelabc*post

replace percentattend34=100* percentattend34
su percentattend34

replace percentattend12=100*percentattend12

areg percentattend34  abc highlevela highlevel cohort2009 time female if time==2,abs(avc) robust cluster(codev)
	outreg2 highlevel highlevela abc using "$df/table7.xls", dec(2) replace excel ctitle("`i'") nocons

test highlevela=highlevel

//Reject equality of coefficients

test highlevela=abc

areg percentattend12 abc highlevela highlevel cohort2009 time female if time==2,abs(avc) robust cluster(codev)
	outreg2 highlevel highlevela abc using "$df/table7.xls", dec(2) append  excel ctitle("`i'") nocons
	sleep 500

test highlevela=highlevel
clear

***********************;
*TABLE 8:  HOTLINE DATA;
***********************;

use "$df/ABChotline.dta", clear

su meanteacher, det
gen highlevel=meanteacher>r(mean) if meanteacher!=.
gen highlevelabc=abc*highlevel
gen lowlevel=meanteacher<=r(mean) if meanteacher!=.
gen lowlevelabc=abc*lowlevel

areg hotline abc cohort2009, abs(avcode) robust
outreg2 abc using "$df/table8hotline.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 500
	
areg hotline abc cohort2009 if highlevel==1, abs(avcode) robust
outreg2 abc using "$df/table8hotline.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 500

areg hotline abc cohort2009 if lowlevel==1, abs(avcode) robust
outreg2 abc using "$df/table8hotline.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 500	

clear

**************************;
*TABLE 9*; CELLPHONE USAGE;
**************************;

use "$df/ABChousehold.dta", clear

//Use the follow-up data

keep if year==2010|year==2011
gen N=_n

gen anybip=.
replace anybip=1 if bip==1|receivebip==1
replace anybip=0 if anybip!=1 & usecellphone==1

foreach i in cellphoneowner accesscellphone usecellphone makecall receivecall writesms receivesms anybip madetransferSMS receivedtransferSMS communicate_migrant celltalkrelativeniger celltalktradeniger whycell_ceremony whycell_help whycell_priceinfo{
	bys abc: su `i' 
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "$df/Table9.xls", dec(2) append excel ctitle ("`var'") nocons
	}

clear
*/
**********************************************************;
*APPENDIX TABLES*;
**********************************************************;

********************************;
*TABLE A1.  ABSENTEISM BY ROUND*;
********************************;

use "$df/ABCtestscore.dta", clear

*This generates a drop-out variable based upon attendance in the first four months of the teaching*;

gen drop12= (attend1==0|attend2==0) if (totaldays12!=.) & (time==2)
gen drop34=(attend3==0|attend4==0)  if (totaldays34!=.) & (time==2)

replace absent=1 if absent==.
gen absent24=absent if time==2|time==4
gen absent35=absent if time==3|time==4

foreach i in drop12 drop34 {
	bys abc: su `i' if time==2|time==4
	xi: reg `i' abc i.avc, robust cluster(codev) 
}

foreach i in absent {
	bys abc: su `i' if time==2|time==4
	xi: reg `i' abc i.avc if time==2|time==4, robust cluster(codev) 
	outreg2 abc using "$df/tablea1.xls", dec(2) append excel ctitle("`i'") 	nocons
	bys abc: su `i' if time==3|time==5
	xi: reg `i' abc i.avc if time==3|time==5, robust cluster(codev) 
	outreg2 abc using "$df/tablea1.xls", dec(2) append excel ctitle("`i'") 	nocons
}

foreach i in age female {
	bys abc: su `i' if (time==2|time==4) & absent==1
	xi: reg `i' abc  i.avc if (time==2|time==4) & absent==1, robust cluster(codev) 
	outreg2 abc using "$df/tablea1.xls", dec(2) append excel ctitle("`i'") 	nocons
	sleep 600
	bys abc: su `i' if (time==3|time==5) & absent==1
	xi: reg `i' abc  i.avc if (time==3|time==5) & absent==1, robust cluster(codev) 
	outreg2 abc using "$df/tablea1.xls", dec(2) append excel ctitle("`i'") 	nocons
	sleep 600
}

clear

*******************************************;
*TABLE A2: TEACHER CHARACTERISTICS BY YEAR*;  
*******************************************;

use "$df/ABCtestscore.dta", clear

bys codev: keep if _n==1
keep codev
merge 1:m codev using "$df/ABCteacher.dta"

tab _m
drop if _m==2

*This does not control for AV fixed effects because not enough obs*

foreach i in levelno teacherage femaleteacher local {
	bys abc: su `i' if year==2009
	reg `i' abc if year==2009, robust cluster(codev)
	outreg2 abc using "$df/tablea2.xls", dec(2) append excel nocons ctitle("`i'")
	sleep 500
	}

foreach i in levelno teacherage femaleteacher local  {
	bys abc: su `i' if year==2010
	reg `i' abc if year==2010, robust cluster(codev)
	outreg2 abc using "$df/tablea2.xls", dec(2) append excel nocons ctitle("`i'")
	sleep 500
	}

**************************************************************;
*TABLE A3:  SIMPLE DIFFERENCE RESULTS AND VALUE-ADDED RESULTS*;
**************************************************************;

use "$df/ABCtestscore.dta", clear

//The value-added specification requires identifying the baseline value for students and the "studentid" variable.  This is not included in the dataset for confidentiality reasons.  Researchers interested in this variable can contact the authors.

gen helpbaselinew=writezs if round==1
gen helpbaselinem=mathzs if round==1

/*
bys codev studentid round: assert _n==1
bys codev studentid (round): egen baselinewritezscore=max(helpbaselinew)
bys codev studentid (round): egen baselinemathzscore=max(helpbaselinem)
*/

* Columns 1 and 2: Simple post-difference

keep if time==2|time==4

*initialize outreg
reg write abc , robust cluster(codev)
	outreg2 abc using "$df/tablea3diff.xls", replace excel nocons ctitle("`i'") dec(3)

foreach i in writezscore mathzscore {
	reg `i' abc cohort2009 female age, robust cluster(codev)
	outreg2 abc cohort2009 female age using "$df/tablea3diff.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000

	areg `i' abc cohort2009 female age , abs(avc) robust cluster(codev)
	outreg2 abc cohort2009 female age using "$df/tablea3diff.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	}


*Columns 3 and 4:  Value-added specification
use "$df/ABCtestscore.dta", clear

reg write abc , robust cluster(codev)
	outreg2 abc using "$dp/tablea3va.out", replace excel nocons ctitle("`i'") dec(3)
	
/*value added
foreach i in writezscore mathzscore {
	reg `i' abc baseline`i' cohort2009 female age, robust cluster(codev)
	outreg2 abc baseline`i' cohort2009 female age using "$df\tablea3va.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000

	areg `i' abc baseline`i' cohort2009 female age, abs(avc) robust cluster(codev)
	outreg2 abc baseline`i' cohort2009 female age using "$dp\tablea3va.xls", append excel nocons ctitle("`i'") dec(3)
	*sleep 1000
	}
*/

*Columns 5 and 6: ALternative normalization using baseline non-ABC distribution

use "$df/ABCtestscore.dta", clear
capture drop mathz* writez* 

foreach sub in math write {
* generate mean and standard deviation in the control group
bys region time: egen hmeanscore`sub'=mean(`sub') if time==1&abc==0 
bys region time: egen hstd`sub'=sd(`sub') if time==1&abc==0
bys region: egen meanscore`sub'=max(hmeanscore`sub')
bys region: egen std`sub'=max(hstd`sub')
gen `sub'zscore=(`sub'-meanscore`sub')/std`sub'
drop hmeansc hstd 
*drop meanscore`sub' std`sub'
}

bys time: su mathz* writez*

keep if round==1|round==2|round==4

foreach i in writezscore mathzscore{
	reg `i' abcpost abc post, robust cluster(codev)
	sleep 1000
	reg `i' abcpost abc post cohort2009 female age dosso , robust cluster(codev)
	outreg2 abcpost abc cohort2009 female age using "$df/tablea3altnorm.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	areg `i' abcpost abc post cohort2009 female age , abs(avcode) robust cluster(codev)
	outreg2 abcpost abc cohort2009 female age using "$df/tablea3altnorm.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 1000
	areg `i' abcpost post female age, abs(codev) robust cluster(codev)
	}

********************************************;
*TABLE A4:  Heterogenenous RESULTS OVER TIME*;
********************************************;

use "$df/ABCtestscore.dta", clear
		reg write abcpost abc 
	      	outreg2 abcpost abc using "$df/tablea4.xls", replace excel nocons 


keep if round==1|round==2|round==4


foreach i in writezscore mathzscore{

	xi: reg `i'  abcpost5m abcpost17m post5m  post17m abc i.avcode, robust cluster(codev)
	outreg2 abcpost5m abcpost17m post5m  post17m abc using "$dp/tablea4.xls", append excel nocons
	test abcpost5m=abcpost17m
	sleep 500
	xi: reg `i'  abcpost5m abcpost17m post5m  post17m cohort2009 abc female age i.avcode, robust cluster(codev)
	outreg2 abcpost5m abcpost17m post5m  post17m abc using "$dp/tablea4.xls", append excel nocons
	test abcpost5m=abcpost17m
	sleep 500

	
	}
*/
*
clear

*******************;
*TABLE A5 BOUNDING*;
*******************;

use "$df/ABCtestscore.dta", clear

//There was more absenteeism on the day of the January tests in the T villages, so drop from C villages
//The parametric trimming used is therefore: .81-.80/.80=.0125, or 1/50th
//Lower bound: Drop lowest 1% of observations from C group, calculate treatment effect
//Upper bound: Drop highest 1% of observations from C group, calculate treatment effect

//Parametric bounding
_pctile writezs if round==3|round==5, p(1, 99)
return list
_pctile mathzs if round==3|round==5, p(1, 99)
return list

//Drop upper 1%
drop if writezsc>=2.73 & abc==0 & (round==3|round==5)
drop if mathzsc>=1.818 & abc==0 & (round==3|round==5)

foreach i in writezsc mathzsc{
	areg `i'  abcpost post abc abcpost6m post6m cohort2009 female age, abs(avcode) robust cluster(codev)
	outreg2 abcpost post abc abcpost6m post6m cohort2009 female age using "$df/tablea5.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 500
	}

clear

//Drop lower 1%


use "$df/ABCtestscore.dta", clear
drop if writezsc<= -1.34 & abc==0 & (round==3|round==5)
drop if mathzsc<= -1.84 & abc==0 & (round==3|round==5)
foreach i in writezsc mathzsc{
	areg `i'  abcpost post abc abcpost6m post6m cohort2009 female age, abs(avcode) robust cluster(codev)
	outreg2 abcpost post abc abcpost6m post6m cohort2009 female age using "$df/tablea5.xls", append excel nocons ctitle("`i'") dec(3)
	sleep 500
	}
clear
	
***********************************************;
*TABLE A6:  CHARACTERISTICS OF HOTLINE CALLERS*;
***********************************************;

	
//The individual hotline data are not posted.  Please contact the authors for these data.
