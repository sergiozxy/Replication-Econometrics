cd "E:\umich\Replication-Econometrics\02. Datasets"

use "ABChousehold.dta", clear

label variable age "age"

preserve
    describe, replace clear
    list
    export excel using variable__label_correspondence.xlsx, replace first(var)
restore

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
// I will save these results to word, and use python to combine the word to latex

logout, save("ttest_with_result.rtf") word replace: ttable3 kou yiji erji sanji end_price_pers pop light pm25 $Control_Variables, by(abc) tvalue
logout, save("ttest_with_result_mean_std.rtf") word replace: tabstat kou yiji erji sanji end_price_pers pop light pm25 $Control_Variables, by(abc) stat(mean sd) nototal long col(stat)



// report the mean and standard deviation

estpost tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal col(stat)

logout, save(ttest_with_result_mean_std) dta replace: tabstat $Pre_Test_Variables, by(abc) stat(mean sd) nototal long col(stat) label


foreach i in $Pre_Test_Vaiables{
	bys abc: su `i'
	reg `i' abc, robust cluster(codev)
	xi: reg `i' abc i.avcode, robust cluster(codev)
	outreg2 abc using "Table1_PanelA.xls", dec(2) append excel ctitle ("`var'")	nocons
	}

	
// now run the python code in jupyter notebook to generate the latex table in paper.
	
clear