/*
Nils Enevoldsen
Collaborating with Beth Spink
For MIT 14.771 PS1, Fall 2016

Replicates Duflo, Esther. "Schooling and Labor Market Consequences of School
Construction in Indonesia: Evidence from an Unusual Policy Experiment." The
American Economic Review 91.4 (2001): 795-813.
*/

version 14.2
clear all
cd ~/Documents/771/771-PS1
log using log, replace text

use inpresdata_mod

// Drop single datapoint with grossly insufficient data.
drop if _n == 149120

// There should be 152,989 individuals in the sample.
assert _N ==  152989

// First, define the “young” as those born between 1968 and 1972, who were
// exposed to the INPRES school construction program the entire time they were
// in primary school (they were 2 to 6 years old in 1974). Define the “old” as
// those born between 1957 and 1962, who should have had little or no exposure
// to the program (they were 12 to 17 in 1974). For the moment, ignore the “very
// old” who were born before 1957.
assert !mi(birthyear)
generate young   = (68 <= birthyear) & (birthyear <= 72)
generate old     = (57 <= birthyear) & (birthyear <= 62)
generate veryold = (birthyear < 57)

// Next, define “high” program areas as those in which the residual of a
// regression of the number of schools on the number of children is positive,
// and all other regions as “low” program areas.
assert !mi(recp)

// 3.1. Generate a new variable - yeduc_diff - which is the difference in the
// average years of education obtained between those born in high and low
// program areas.
//
// Plot this difference on the y axis with cohorts (i.e., birth year) on the
// x axis. Add seperate fitted regression lines for the old and young cohorts.
// Comment on the plot. How does this pattern fit with the author’s argument?
preserve
collapse yeduc [aweight=weight], by(birthyear young old recp)
reshape wide yeduc, i(birthyear young old) j(recp)
gen yeduc_diff = yeduc1 - yeduc0
graph twoway ///
    (line yeduc_diff birthyear) ///
    (lfit yeduc_diff birthyear if young) ///
    (lfit yeduc_diff birthyear if old)
restore

// 3.2. Calculate the average difference in years of education obtained between
// the high and low program areas for the old and the young. Subtract your
// measure for the old from your measure for the young. Provide standard errors
// for these differences. Repeat the procedure for the log of hourly wages. What
// do we call this estimator?
preserve
keep if (young | old) & !mi(lhwage)
mean yeduc [aweight=weight], over(recp old)
lincom  (_subpop_3 - _subpop_1) - (_subpop_4 - _subpop_2)
mean lhwage [aweight=weight], over(recp old)
lincom  (_subpop_3 - _subpop_1) - (_subpop_4 - _subpop_2)
restore

// 3.3. [Discussion question omitted.]

// 3.4. Now define one more group - the “very old” - born before 1957 (in
// practice, because we only have data beginning in 1950, this encompasses
// individuals born between 1950 and 1956, who were thus 18 to 24 years old in
// 1974). Repeat the above analysis from 3.2 and 3.3, comparing the old and very
// old. Why is this exercise useful? What should you see if the identifying
// assumptions hold? Comment on your plot.
preserve
collapse yeduc [aweight=weight], by(birthyear old veryold recp)
reshape wide yeduc, i(birthyear old veryold) j(recp)
gen yeduc_diff = yeduc1 - yeduc0
graph twoway ///
    (line yeduc_diff birthyear) ///
    (lfit yeduc_diff birthyear if old) ///
    (lfit yeduc_diff birthyear if veryold)
restore

preserve
keep if (old | veryold) & !mi(lhwage)
mean yeduc [aweight=weight], over(recp veryold)
lincom  (_subpop_3 - _subpop_1) - (_subpop_4 - _subpop_2)
mean lhwage [aweight=weight], over(recp veryold)
lincom  (_subpop_3 - _subpop_1) - (_subpop_4 - _subpop_2)
restore

// 5.2. Aggregate the data by cohort (young and old) and region of birth. Run a
// regression of (a) education on school construction program intensity and (b)
// wages on school construction program intensity. Calculate the ratio of (b) to
// (a). What is this called? Discuss how the results compare to Table 7.

// Alternative approach to replicating Table 7, Panel A1
preserve
keep if !mi(lhwage)

local controls1 "i.birthpl i.birthyear i.birthyear#(c.ch71)"
local controls2 "i.birthpl i.birthyear i.birthyear#(c.ch71 c.en71)"
local controls3 "i.birthpl i.birthyear i.birthyear#(c.ch71 c.en71 c.wsppc)"

eststo, prefix(ols): qui reg lhwage yeduc `controls1' [aweight=weight]
eststo, prefix(ols): qui reg lhwage yeduc `controls2' [aweight=weight]
eststo, prefix(ols): qui reg lhwage yeduc `controls3' [aweight=weight]

eststo, prefix(iv_year): qui ivregress 2sls lhwage ///
    (yeduc=i.birthyear#i.recp) `controls1' [aweight=weight]
eststo, prefix(iv_year): qui ivregress 2sls lhwage ///
    (yeduc=i.birthyear#i.recp) `controls2' [aweight=weight]
eststo, prefix(iv_year): qui ivregress 2sls lhwage ///
    (yeduc=i.birthyear#i.recp) `controls3' [aweight=weight]

eststo, prefix(iv_cohort): qui ivregress 2sls lhwage ///
    (yeduc=i.young#i.recp) `controls1' [aweight=weight]
eststo, prefix(iv_cohort): qui ivregress 2sls lhwage ///
    (yeduc=i.young#i.recp) `controls2' [aweight=weight]
eststo, prefix(iv_cohort): qui ivregress 2sls lhwage ///
    (yeduc=i.young#i.recp) `controls3' [aweight=weight]

esttab ols*, keep(yeduc)
esttab iv_year*, keep(yeduc)
esttab iv_cohort*, keep(yeduc)
restore

log close
