cd "P:\svo\20250806 devecon"

u "Data\prepared_data", replace

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


logit followed_lime_1all 1.treated 1.treated#c.num_messages i.program, or // dose response


logit followed_lime_1all 1.treated 1.treated#(c.age_decades c.age_squared) age_decades age_squared  i.program,  // nonlinear age response

logit followed_lime_1all 1.treated 1.treated#i.female_b#(c.age_decades c.age_squared) age_decades age_squared 1.female_b i.program,  // nonlinear age response

logit followed_lime_1all 1.treated female_b large_shamba_b c.age_decades c.age_squared i.program 

logit followed_lime_1all (1.treated i.program)##(1.female_b 1.large_shamba_b c.age_decades c.age_squared) 

logit followed_lime_1all (1.treated i.program)##(1.large_shamba_b ever_used_lime_b) 


logit followed_lime_1all i.program
logit followed_lime_1all 1.treated i.program
logit followed_lime_1all 1.treated##i.program