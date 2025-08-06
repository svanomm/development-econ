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
drop followed_lime_1a followed_lime_2a

gen followed_fert_1all=followed_fert_1a
replace followed_fert_1all=followed_fert_2a if sample=="KALRO"
drop followed_fert_1a followed_fert_2a

* Make heterogeneity variables comparable across projects
* for primary - use endline value if baseline not available
gen primary_all=primary_b
replace primary_all=primary if primary_all==.
drop primary_b primary

* for lime awareness - use knowledge if awareness not available
gen hear_knows_lime_b=heard_lime_b
replace hear_knows_lime_b=mention_lime_b if hear_knows_lime_b==.
drop heard_lime_b mention_lime_b

* drop fixed effects
drop FO_id_KALRO_* location_KALRO_* location_PAD1_* location_PAD2_* agrovet_PAD2_* location_OAF1_* location_OAF2_* location_OAF3_*

*keep id sample partial_treat_control hasphone program followed_lime_1all followed_fert_1all primary_all hear_knows_lime_b female_b primary_all large_shamba_b d_young_b hear_knows_lime_b used_fert_b ever_used_lime_b  heard_fert_b treated num_messages age_b

g age_decades = age_b/10
g age_squared = age_decades^2

save "P:\svo\20250806 devecon\Data\prepared_data", replace
export delimited "P:\svo\20250806 devecon\Data\prepared_data.csv", replace
