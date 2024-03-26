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


use "$df/ABCtestscore.dta", replace
global charlist "writez1 mathz1"

foreach i of global charlist {
	bys abc: su `i'
	xi: reg `i' abc i.avc, cluster(codev)
	outreg2 abc using "$df/Table2.xls", dec(2) append excel ctitle ("`var'") 	nocons	
	}

clear

// now run the python code in jupyter notebook to generate the latex table in paper.

/* Difference-In-Difference Estimation*/

use "ABCtestscore.dta", clear

keep if round==1|round==2|round==4



clear