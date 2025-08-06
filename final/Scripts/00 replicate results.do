********************************************************************************
* 4_supplementary_analysis.do
			
* Purpose of the do-file: it creates auxiliary tables for appendix
********************************************************************************

use "${data}/intermediate/pooled_experiments.dta", clear
isid id, sort
set seed 684806	// extracted from random.org on 2024-04-15 19:52:40 UTC

//Keep relevant sample for OAF3
drop if sample=="OAF3" &  (partial_treat_control==1 | hasphone==0) 

//Convert variable for program FE
encode sample, gen(program)

//Create comparable variables for pooled regressions 	
gen followed_lime_1all=followed_lime_1a
replace followed_lime_1all=followed_lime_2a if sample=="KALRO"

gen followed_fert_1all=followed_fert_1a
replace followed_fert_1all=followed_fert_2a if sample=="KALRO"

    *Lime (ols)
	reg followed_lime_1all treated i.program,  vce (bootstrap)
	matrix res = r(table)
	loc b1: display %04.3f res[1, 1]
	loc se1: display %04.3f res[2, 1]
	sum followed_lime_1all if e(sample)==1 & treated==0
	loc n1= string(`r(N)',"%10.0fc")
	
    reg followed_lime_1all treated i.program,  vce (cluster program)
	matrix res = r(table)
	loc sec1: display %04.3f res[2, 1]
	boottest treated, nograph reps(9999)
	loc pvalc1: display %04.3f r(p)
	sum followed_lime_1all if e(sample) == 1 & treated==0
	loc b_baset1= string(`r(mean)',"%04.3f")
	
	*Fertilizer (ols)
	eststo: reg followed_fert_1all treated i.program,  vce (bootstrap)
	matrix res = r(table)
	loc b2: display %04.3f res[1, 1]
	loc se2: display %04.3f res[2, 1]
	sum followed_fert_1all if e(sample)==1 & treated==0
	loc n2= string(`r(N)',"%10.0fc")
	
	eststo: reg followed_fert_1all treated i.program,  vce (cluster program)
	matrix res = r(table)
	loc sec2: display %04.3f res[2, 1]
	boottest treated, nograph   reps(999999)
	loc pvalc2: display %04.3f r(p)
	sum followed_fert_1all if e(sample) == 1 & treated==0
	loc b_baset2= string(`r(mean)',"%04.3f")

	*Lime (logit)
	logit followed_lime_1all treated i.program,  or vce (bootstrap)
	matrix res = r(table)
	loc b3: display %04.3f res[1, 1]
	loc se3: display %04.3f res[2, 1]
	sum followed_lime_1all if e(sample)==1
	loc n3= string(`r(N)',"%10.0fc")
	
	logit followed_lime_1all treated i.program,  or vce (cluster program)
	matrix res = r(table)
	loc sec3: display %04.3f res[2, 1]
	boottest treated, nograph  reps(999999)
	loc pvalc3: display %04.3f r(p)
	sum followed_lime_1all if e(sample) == 1 & treated==0
	loc b_baset3= string(`r(mean)',"%04.3f")

	*Fertilizer (logit)
	logit followed_fert_1all treated i.program, or vce (bootstrap)
	matrix res = r(table)
	loc b4: display %04.3f res[1, 1]
	loc se4: display %04.3f res[2, 1]
	sum followed_fert_1all if e(sample)==1
	loc n4= string(`r(N)',"%10.0fc")
	
	logit followed_fert_1all treated i.program, or vce (cluster program)
	matrix res = r(table)
	loc sec4: display %04.3f res[2, 1]
	boottest treated, nograph  reps(999999)
	loc pvalc4: display %04.3f r(p)
	sum followed_fert_1all if e(sample) == 1 & treated==0
	loc b_baset4= string(`r(mean)',"%04.3f")

texdoc init "${tables_a}/pooled_regressions.tex", replace force

tex    Treated & `b1'    & `b2'  & `b3' & `b4' \\	
tex    & (`se1')    & (`se2')  & (`se3') & (`se4') \\
tex    &    &   &  &  \\		
tex    & $\langle`sec1'\rangle$  & $\langle`sec2'\rangle$ &  $\langle`sec3'\rangle$   & $\langle`sec4'\rangle$ \\
tex     & [`pvalc1']  & [`pvalc2']  &  [`pvalc3'] & [`pvalc4'] \\	
tex     Mean Control  &  `b_baset1'   &  `b_baset2'  & `b_baset3'  & `b_baset4' \\
tex     Observations & `n1' & `n2' & `n3' & `n4' \\

texdoc close

eststo clear

//Heterogeneity 

gen x=.
gen x_sms=.
label var x  "$[X]$ "
label var  x_sms "$[X]$ *Treated"

* Make heterogeneity variables comparable across projects
* for primary - use endline value if baseline not available
gen primary_all=primary_b
replace primary_all=primary if primary_all==.

* for lime awareness - use knowledge if awareness  not available
gen hear_knows_lime_b=heard_lime_b
replace hear_knows_lime_b=mention_lime_b if hear_knows_lime_b==.

foreach var in female_b primary_all large_shamba_b d_young_b hear_knows_lime_b used_fert_b ever_used_lime_b  heard_fert_b {
	tab `var'
	gen `var'_sms = `var'*treated	
}

// Pooled Heterogeneity regressions
eststo clear
foreach var in female_b primary_all large_shamba_b d_young_b ever_used_lime_b hear_knows_lime_b  {
	replace x=`var'
	replace  x_sms=`var'_sms  

	eststo: reg followed_lime_1all treated  x x_sms (i.program)##x, vce(bootstrap) 
	sum followed_lime_1all if e(sample) == 1 & treated==0
	estadd scalar mean = r(mean) 
	estadd local space "  "

}
		
foreach var in female_b primary_all large_shamba_b d_young_b ever_used_lime_b hear_knows_lime_b  {
	replace x=`var'
	replace  x_sms=`var'_sms  

	eststo: logit followed_lime_1all treated  x x_sms (i.program)##x, vce(bootstrap) or
	sum followed_lime_1all if e(sample) == 1 & treated==0
	estadd scalar mean = r(mean) 
	estadd local space "  "

}

esttab using "${data}/intermediate/pooled_lime_het.csv" ,  keep(  x treated x_sms  ) eform (0 0 0 0 0 0 1 1 1 1 1 1)  /*
*/ nomtitles order(  treated x x_sms )style(tex) fragment booktabs   cells(b(star fmt(%9.3f)) se(par))  /*
*/ stats(space  mean N , fmt(%9.0g  %9.2f %9.0f) labels(" " "Mean Control" "Observations" )) /*
*/ nolegend label collabels(none) plain star(* .10 ** .05 *** .01)    replace
eststo clear

preserve
	import delimited "${data}/intermediate/pooled_lime_het.csv", clear
	drop if _n==1
	export delimited using  "${tables_a}/pooled_lime_het.tex", replace    novarnames
restore

erase "${data}/intermediate/pooled_lime_het.csv"

 foreach var in female_b primary_all large_shamba_b d_young_b  used_fert_b heard_fert_b {
	replace x=`var'
	replace  x_sms=`var'_sms  

	eststo: logit followed_fert_1all treated  x x_sms (i.program)##x,  vce(bootstrap) 
	sum followed_fert_1all if e(sample) == 1 & treated==0
	estadd scalar mean = r(mean) 
	estadd local space "  "

}

foreach var in female_b primary_all large_shamba_b d_young_b  used_fert_b heard_fert_b {
	replace x=`var'
	replace  x_sms=`var'_sms  

	eststo: logit followed_fert_1all treated  x x_sms (i.program)##x,  vce(bootstrap) or
	sum followed_fert_1all if e(sample) == 1 & treated==0
	estadd scalar mean = r(mean) 
	estadd local space "  "

}
 
esttab using "${data}/intermediate/pooled_fert_het.csv" ,  keep( x treated x_sms   )  eform (0 0 0 0 0 0 1 1 1 1 1 1) /*
*/ nomtitles order(   treated x  x_sms )style(tex) fragment booktabs   cells(b(star fmt(%9.3f)) se(par))  /*
*/ stats(space  mean N , fmt(%9.0g  %9.2f %9.0f) labels(" " "Mean Control" "Observations" )) /*
*/ nolegend label collabels(none) plain star(* .10 ** .05 *** .01)    replace
eststo clear

preserve
	import delimited "${data}/intermediate/pooled_fert_het.csv", clear
	drop if _n==1
	export delimited using  "${tables_a}/pooled_fert_het.tex", replace    novarnames
restore 

erase "${data}/intermediate/pooled_fert_het.csv"

