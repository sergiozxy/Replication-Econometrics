*** Program name: Sample Do File.do

* NOTE:  Whenever a line begins with an asterisk, STATA ignores the whole line - this is just a comment/note.
capture log close
clear /* The 'clear' command gets rid of all data in memory*/
set memory 60000 /* Allocate 60MB memory to Stata */
set matsize 150
set more 1

* This line tells Stata where the files are located. USE "" if your folder names contain spaces.
* THIS IS THE ONLY LINE YOU NEED TO CHANGE. 

cd "C:\Users\Asja\Desktop\Cell replication Mar 6\ABC Data and Do Files"


* NOTE:  The next lines set up the .log file.  It will contain all of the output
* from this program when it is run. It will be saved in the same directory as the
* program and will be replaced with each new run. I have called the log-file ProblemSet1. 
log using Replication_v2.log, replace

* This line reads in the data set called WAGE2.dta in the same directory (in my case this is directory "Datasets").


* I. SAMPLE STATISTICS: TABLE 1

*For the households:

use "ABChousehold.dta", clear

ttest age if year==2009, by (abc)


*For the teachers:

use "ABCteacher.dta", clear

ttest teacherage if year==2009, by (abc)

*For testcores

use "ABCtestscore.dta", clear

ttest writezscore if year==2009, by (abc)

* II. DID RESULTS - TABLE 2

use "ABCtestscore.dta", clear
* OUTCOME: mathzscore 

reg mathzscore abc post abcpost, robust

log close

exit, clear
