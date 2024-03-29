*** Program name: Sample Do File.do

* NOTE:  Whenever a line begins with an asterisk, STATA ignores the whole line - this is just a comment/note.
capture log close
clear /* The 'clear' command gets rid of all data in memory*/
set memory 60000 /* Allocate 60MB memory to Stata */
set matsize 150
set more 1

* This line tells Stata where the files are located. USE "" if your folder names contain spaces.
* THIS IS THE ONLY LINE YOU NEED TO CHANGE. 

* NOTE:  The next lines set up the .log file.  It will contain all of the output
* from this program when it is run. It will be saved in the same directory as the
* program and will be replaced with each new run. I have called the log-file ProblemSet1. 

cd "C:\Users\zxuyuan\Downloads\02. Datasets"

log using Replication_v2.log, replace

// before using the stata do file you need to install
// esttab: ssc install estout
// outreg2: ssc install outreg2

use "ABChousehold.dta", clear

/***************TABLE 0 *******************/
// Export the label and variable name

label variable age "age"
// this code is to export the name and label for further use. (make table in python)

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence.xlsx, replace first(var)
restore

use "ABCteacher.dta", clear

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence_teacher.xlsx, replace first(var)
restore

use "ABCtestscore.dta", clear

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence_test_score.xlsx, replace first(var)
restore

/***************TABLE 1 *******************/
// We test whether the treatment group is assigned via non-randomization manipulation

use "ABCtestscore.dta", clear

reg writez1 abc i.avc, cluster(codev)
est store base_line_1

reg writez1 abc female age dosso i.avc, cluster(codev)
est store base_line_2

reg mathz1 abc i.avc, cluster(codev)
est store base_line_3

reg mathz1 abc female age dosso i.avc, cluster(codev)
est store base_line_4

esttab base_line_1 base_line_2 base_line_3 base_line_4 ///
 using ../manuscript/Tables/baseline_check.tex, ///
style(tex) booktabs keep(abc) ///
mtitle("log(income)" "price concession" "log(lead times)") ///
star(* 0.1 ** 0.05 *** 0.01) ///
se ///
scalars("r2 R-squared") ///
 replace

/***************TABLE 2 *******************/

use "ABChousehold.dta", clear

keep if year==2009

/******** NOTE ********/

// For Table one, I generated two versions 
// one version is consistent with the description of the guide file
// another version is consistent with the original paper's result, because:
// I think the original paper's method is better, because it clusters the result to village level
// furthermore, it uses the subdistrict's fixed effect in the model.
// this is more robust than naive comparision of the difference

global Pre_Test_Variables age hhhead eth_hausa hhmem_no edchild_percent assets drought cellphone accesscellphone usecellphone makecall receivecall  

// summary statistics
// I will save these results to stata dta, and use python to combine the result to latex

/*
logout, save("ttest_with_result") dta replace: ttable3 $Pre_Test_Variables, by(abc) tvalue
logout, save("ttest_with_result_mean_std") dta replace: tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal long col(stat)
*/

// report the mean and standard deviation

tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal long col(stat)
outreg2 using ttest_with_result_mean_std.dta, replace


foreach i in $Pre_Test_Variables{
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "Table1_PanelA", dec(2) append dta ctitle ("`var'")	nocons
}

use "ABCtestscore.dta", clear

bys codev: keep if _n==1
keep codev
merge 1:m codev using "ABCteacher.dta"

// note that during our operation, we have dropped some of the codes that are not contained in the test score result.
// because these are not relevant to our study.
tab _m
drop if _m==2

tabstat levelno teacherage femaleteacher local, by(abc) stat(mean sd) nototal long col(stat)
outreg2 using Table1_PanelB_mean_std.dta, replace

foreach i in levelno teacherage femaleteacher local{
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "Table1_PanelB", dec(2) append dta ctitle ("`var'")	nocons
	}

use "ABCtestscore.dta", clear

tabstat writez1 mathz1, by(abc) stat(mean sd) nototal long col(stat)
outreg2 using Table1_PanelC_mean_std.dta, replace


foreach i of varlist writez1 mathz1 {
	xi: reg `i' abc i.avc, cluster(codev)
	outreg2 abc using "Table1_PanelC", dec(2) append dta ctitle ("`var'")	nocons
	}

// now run the python code in jupyter notebook to generate the latex table in paper.

/***************TABLE 3 *******************/
/* Difference-In-Difference Estimation*/

use "ABCtestscore.dta", clear

keep if round==1|round==2|round==4

regress writezscore abc post abcpost i.avc, robust cluster(codev)
est store did_1

regress mathzscore abc post abcpost i.avc, robust cluster(codev)
est store did_2

regress writezscore abc post abcpost age female zarma kanuri dosso i.avc, robust cluster(codev)
est store did_3

regress mathzscore abc post abcpost age female hausa zarma kanuri dosso i.avc, robust cluster(codev)
est store did_4

generate agesq = age * age
regress writezscore abc post abcpost age agesq female zarma kanuri dosso i.avc, robust cluster(codev)
est store did_5

regress mathzscore abc post abcpost age agesq female zarma kanuri dosso i.avc, robust cluster(codev)
est store did_6

qui tab codevillage, gen(village_dum)

reg writezscore abc post abcpost age agesq female village_dum*, robust cluster(codev)
est store did_7

reg mathzscore abc post abcpost age agesq female village_dum*, robust cluster(codev)
est store did_8

esttab did_* ///
 using ../manuscript/Tables/did_result.tex, ///
style(tex) booktabs keep(abc post abcpost age agesq female) ///
mtitle("literacy" "math" "literacy" "math" "literacy" "math" "literacy" "math") ///
star(* 0.1 ** 0.05 *** 0.01) ///
se ///
scalars("r2 R-squared") ///
 replace
 
/***************TABLE 4 *******************/
/* Difference-In-Difference-In-Difference Estimation*/

use "ABCtestscore.dta", clear

keep if round==1|round==2|round==4

generate agesq = age * age
capture drop region regionpost regionabc abcregionpost
gen region=dosso==1
gen regionpost=region*post
gen regionabc=region*abc
gen abcregionpost=regionabc*post
	
reg writezscore abcpost abc post region regionpost regionabc abcregionpost cohort2009 female age agesq i.avc, robust cluster(codev)  
est store ddd_1

reg mathzscore abcpost abc post region regionpost regionabc abcregionpost cohort2009 female age agesq i.avc, robust cluster(codev)  
est store ddd_2

reg writezscore abc female post femalepost femaleabc abcpost abcfemalepost cohort2009 age agesq i.avc, robust cluster(codev)
est store ddd_3

reg mathzscore abc female post femalepost femaleabc abcpost abcfemalepost cohort2009 age agesq i.avc, robust cluster(codev)
est store ddd_4

esttab ddd_* ///
 using ../manuscript/Tables/ddd.tex, ///
style(tex) booktabs keep(abc female post femalepost femaleabc abcpost abcfemalepost cohort2009 age agesq) ///
mtitle("literacy" "math" "literacy" "math") ///
star(* 0.1 ** 0.05 *** 0.01) ///
se ///
scalars("r2 R-squared") ///
 replace


log close
exit, clear
