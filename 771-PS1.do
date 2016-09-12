/*
Nils Enevoldsen
Collaborating with Beth Spink
For MIT 14.771 PS1, Fall 2016

Replicates Duflo, Esther. "Schooling and Labor Market Consequences of School
Construction in Indonesia: Evidence from an Unusual Policy Experiment." The
American Economic Review 91.4 (2001): 795-813.
*/

version 14.1

clear all

cd ~/Documents/771/771-PS1

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
generate young = (68 <= birthyear) & (birthyear <= 72)
generate old   = (57 <= birthyear) & (birthyear <= 62)

// Next, define “high” program areas as those in which the residual of a
// regression of the number of schools on the number of children is positive,
// and all other regions as “low” program areas.
//
// [Note: This program intensity variable is already generated for you in the
// dataset, and is labeled “recp”.]
assert !mi(recp)

// 1. Generate a new variable - yeduc_diff - which is the difference in the
// average years of education obtained between those born in high and low
// program areas.
//
// (Hint: Collapse your data to do this; make sure to limit your sample and
// weight appropriately).
preserve
collapse yeduc [aweight=weight], by(birthyear young old recp)
reshape wide yeduc, i(birthyear young old) j(recp)
gen yeduc_diff = yeduc1 - yeduc0

// Plot this difference on the y axis with cohorts (i.e., birth year) on the
// x axis. Add seperate fitted regression lines for the old and young cohorts.
// Comment on the plot. How does this pattern fit with the author’s argument?
//
// (Hint: Use Stata’s “twoway lfit” command to add regression lines to your
// plot).
graph twoway ///
    (line yeduc_diff birthyear) ///
    (lfit yeduc_diff birthyear if young) ///
    (lfit yeduc_diff birthyear if old)
restore

// 2. Calculate the average difference in years of education obtained between
// the high and low program areas for the old and the young. Subtract your
// measure for the old from your measure for the young. Provide standard errors
// for these differences. Repeat the procedure for the log of hourly wages. What
// do we call this estimator?
//
// (Hint: Your results should match those found in Panel A of Table 3. Don’t
// forget to limit your sample and weight appropriately).
preserve
keep if (young | old) & !mi(lhwage)
*tab old recp [aweight=weight], summ(yeduc)  means standard nofreq noobs
*tab old recp [aweight=weight], summ(lhwage) means standard nofreq noobs
qui reg yeduc  i.old##i.recp [aweight=weight]
margins i.old##i.recp
qui reg lhwage i.old##i.recp [aweight=weight]
margins i.old##i.recp
restore

// 3. [Discussion question omitted.]

// 4. Now define one more group - the “very old” - born before 1957 (in
// practice, because we only have data beginning in 1950, this encompasses
// individuals born between 1950 and 1956, who were thus 18 to 24 years old in
// 1974). Repeat the above analysis from 3.2 and 3.3, comparing the old and very
// old. Why is this exercise useful? What should you see if the identifying
// assumptions hold? Comment on your plot.
//
// (Hint: Don’t forget to limit your sample and weight appropriately).
generate veryold = (birthyear < 57)

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
*tab veryold recp [aweight=weight], summ(yeduc)  means standard nofreq noobs
*tab veryold recp [aweight=weight], summ(lhwage) means standard nofreq noobs
qui reg yeduc  i.veryold##i.recp [aweight=weight]
margins i.veryold##i.recp
qui reg lhwage i.veryold##i.recp [aweight=weight]
margins i.veryold##i.recp
restore