cd "E:\umich\Replication-Econometrics\02. Datasets"

use "ABChousehold.dta", clear

label variable age "age"
// this code is to export the name and label for further use. (make table in python)

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence.xlsx, replace first(var)
restore

	
/* Table 1 */

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
 

clear

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

estpost tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal col(stat)

logout, save(ttest_with_result_mean_std) dta replace: tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal long col(stat) label

foreach i in $Pre_Test_Variables{
	bys abc: su `i'
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "Table1_PanelA", dec(2) append dta ctitle ("`var'")	nocons
}

use "ABCteacher.dta", clear

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence_teacher.xlsx, replace first(var)
restore

use "ABCtestscore.dta", clear

bys codev: keep if _n==1
keep codev
merge 1:m codev using "ABCteacher.dta"

// note that during our operation, we have dropped some of the codes that are not contained in the test score result.
// because these are not relevant to our study.
tab _m
drop if _m==2

logout, save(Table1_PanelB_mean_std) dta replace: tabstat levelno teacherage femaleteacher local, by(abc) stat(mean sd) nototal long col(stat)


foreach i in levelno teacherage femaleteacher local{
	bys abc: su `i' 
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "Table1_PanelB", dec(2) append dta ctitle ("`var'")	nocons
	}
clear


use "ABCtestscore.dta", clear

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence_test_score.xlsx, replace first(var)
restore

logout, save(Table1_PanelC_mean_std) dta replace: tabstat writez1 mathz1, by(abc) stat(mean sd) nototal long col(stat)

foreach i of varlist writez1 mathz1 {
	bys abc: su `i'
	xi: reg `i' abc i.avc, cluster(codev)
	outreg2 abc using "Table1_PanelC", dec(2) append dta ctitle ("`var'")	nocons
	}

clear

// now run the python code in jupyter notebook to generate the latex table in paper.

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

// more test result based on Effects of the ABC Program by Year


reg writezscore abcpost5m abcpost17m post5m  post17m abc age agesq female village_dum*, robust cluster(codev)
est store heterogeneous_check_1

reg writezscore abcpost5m abcpost17m post5m  post17m cohort2009 abc age agesq female village_dum*, robust cluster(codev)
est store heterogeneous_check_2

reg mathzscore abcpost5m abcpost17m post5m  post17m abc age agesq female village_dum*, robust cluster(codev)
est store heterogeneous_check_3

reg writezscore abcpost5m abcpost17m post5m  post17m cohort2009 abc age agesq female village_dum*, robust cluster(codev)
est store heterogeneous_check_4

esttab heterogeneous_check_* ///
 using ../manuscript/Tables/heterogenous_check.tex, ///
style(tex) booktabs keep(abc post abcpost age agesq female) ///
mtitle("literacy" "literacy" "math"  "math") ///
star(* 0.1 ** 0.05 *** 0.01) ///
se ///
scalars("r2 R-squared") ///
 replace



// we also conduct Figure 4.  Impact of the ABC Program on Test Score Achievements


clear