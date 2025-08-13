
cd "P:\svo\20250806 devecon"

use "data/pooled_experiments.dta", clear

* Function to calculate balanced accuracy of logit model
cap program drop balanced_accuracy
program define balanced_accuracy, rclass
    syntax [, Threshold(real 0.5)]
    
    // Check if estimation was done
    if "`e(cmd)'" == "" {
        display as error "No estimation results found"
        exit 301
    }
    
    // Get dependent variable name
    local depvar = e(depvar)
    
    // Predict probabilities
    tempvar pr
    qui predict `pr' if e(sample), pr
    
    // Create binary predictions based on threshold
    tempvar pred
    qui gen `pred' = `pr' >= `threshold' if e(sample)
    
    // Calculate confusion matrix
    qui count if `depvar' == 1 & `pred' == 1 & e(sample)
    local tp = r(N)
    qui count if `depvar' == 0 & `pred' == 0 & e(sample)
    local tn = r(N)
    qui count if `depvar' == 1 & `pred' == 0 & e(sample)
    local fn = r(N)
    qui count if `depvar' == 0 & `pred' == 1 & e(sample)
    local fp = r(N)
    
    // Calculate metrics
    local sensitivity = `tp'/(`tp' + `fn')
    local specificity = `tn'/(`tn' + `fp')
    local balanced_accuracy = (`sensitivity' + `specificity')/2
    
	di "balanced accuracy: `balanced_accuracy'"
	
    // Return results
    return scalar balanced_accuracy = `balanced_accuracy'
end

* Function to test all possible probabilities for best balanced accuracy
cap program drop optimal_accuracy
program define optimal_accuracy, rclass

    // Check if estimation was done
    if "`e(cmd)'" == "" {
        display as error "No estimation results found"
        exit 301
    }
    
    // Get dependent variable name
    local depvar = e(depvar)
    
    // Predict probabilities
    tempvar pr
    qui predict `pr' if e(sample), pr
    
    qui levelsof `pr' if e(sample), local(probs)
	
	local best_p = .
	local best_a = 0
	
	foreach p of local probs {
		foreach eps in -0.0001 0.0001 {
			local x = `p'+`eps'
			
			qui balanced_accuracy, t(`x')
			if r(balanced_accuracy) > `best_a' {
				local best_p = `x'
				local best_a = r(balanced_accuracy)
			}
		}
	}
	
	di "Best accuracy: threshold `best_p', accuracy `best_a'"
	
	return scalar best_threshold = `best_p'
	return scalar best_accuracy  = `best_a'
end

* Data prep
{
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

//Heterogeneity 
gen x=.
gen x_sms=.
label var x  "$X$"
label var  x_sms "$X$ *Treated"

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
}

// Pooled Heterogeneity regressions
eststo clear

* Lime models
local replaceappend "replace"
foreach var in female_b primary_all large_shamba_b d_young_b ever_used_lime_b hear_knows_lime_b  {
	if "`var'" == "primary_all" local replaceappend "append"
	replace x=`var'
	replace  x_sms=`var'_sms  

	logit followed_lime_1all treated  x x_sms (i.program)##x, vce(bootstrap) or
	sum followed_lime_1all if e(sample) == 1 & treated==0
	local mean_control = r(mean)
	
	lroc, nograph
	local auroc = r(area)
	
	optimal_accuracy
	local best_threshold = r(best_threshold)
	local best_accuracy  = r(best_accuracy)
	
	outreg2 using "temp/reg_results_lime", dta `replaceappend' ///
	addstat(Mean Control, `mean_control', AUROC, `auroc', Best Threshold, `best_threshold', Balanced Accuracy, `best_accuracy') ///
	adec(2) bdec(3) sdec(3) ///
	label nonotes ctitle("`var'") addtext("Program FE", "Yes") ///
	eform
}

* Fertilizer models
local replaceappend "replace"
foreach var in female_b primary_all large_shamba_b d_young_b used_fert_b heard_fert_b  {
	if "`var'" == "primary_all" local replaceappend "append"
	replace x=`var'
	replace  x_sms=`var'_sms  
	
	logit followed_fert_1all treated  x x_sms (i.program)##x, vce(bootstrap) or
	sum followed_fert_1all if e(sample) == 1 & treated==0
	local mean_control = r(mean)
	
	lroc, nograph
	local auroc = r(area)
	
	optimal_accuracy
	local best_threshold = r(best_threshold)
	local best_accuracy  = r(best_accuracy)
	
	outreg2 using "temp/reg_results_fert", dta `replaceappend' ///
	addstat(Mean Control, `mean_control', AUROC, `auroc', Best Threshold, `best_threshold', Balanced Accuracy, `best_accuracy') ///
	adec(2) bdec(3) sdec(3) ///
	label nonotes ctitle("`var'") addtext("Program FE", "Yes") ///
	eform
}

* prepare output files
{
u "temp/reg_results_lime_dta", replace
drop in 1/5
drop in 7/45
g sort = _n
replace sort = 99 in 7
sort sort
drop sort
label var v1 "Variable"
label var v2 "Female"
label var v3 "Primary"
label var v4 "Large Farm"
label var v5 "Young"
label var v6 "Used Input"
label var v7 "Heard Input"
save "temp/reg_results_lime_dta", replace

u "temp/reg_results_fert_dta", replace
drop in 1/5
drop in 7/39
g sort = _n
replace sort = 99 in 7
sort sort
drop sort
label var v1 "Variable"
label var v2 "Female"
label var v3 "Primary"
label var v4 "Large Farm"
label var v5 "Young"
label var v6 "Used Input"
label var v7 "Heard Input"
save "temp/reg_results_fert_dta", replace
}

* Output tables to tex
{
u "temp/reg_results_lime_dta", replace

* significance stars
foreach i of var v2-v7 {
	replace `i' = regexs(1) + "$^{" + regexs(2) + "}$" if regexm(`i', "([0-9.]+)([*]+)")
}

* you may need to run this command twice if the output is blank.
texsave * using "output/replicated_lime.tex", replace frag nofix varlabels location("h") hlines(6) title("Replicated Heterogeneity Logit Models: Lime") footnote("Pooled models combine the data from all studies with sufficient data. The dependent variable is whether the farmer followed recommendations for lime or fertilizer. 'Program FE' are fixed effects for each available study; we also include interactions with the control variable. Coefficients are reported as odds ratios. 'AUROC' is the area under the receiver operator curve (higher is better). 'Best Threshold' is the classification threshold that maximizes balanced accuracy. 'Balanced Accuracy' is the average of classification sensitivity and specificity (higher is better).")

u "temp/reg_results_fert_dta", replace

* significance stars
foreach i of var v2-v7 {
	replace `i' = regexs(1) + "$^{" + regexs(2) + "}$" if regexm(`i', "([0-9.]+)([*]+)")
}

texsave * using "output/replicated_fert.tex", replace frag nofix varlabels location("h") hlines(6) title("Replicated Heterogeneity Logit Models: Fertilizer") footnote("Pooled models combine the data from all studies with sufficient data. The dependent variable is whether the farmer followed recommendations for lime or fertilizer. 'Program FE' are fixed effects for each available study; we also include interactions with the control variable. Coefficients are reported as odds ratios. 'AUROC' is the area under the receiver operator curve (higher is better). 'Best Threshold' is the classification threshold that maximizes balanced accuracy. 'Balanced Accuracy' is the average of classification sensitivity and specificity (higher is better).")
}
