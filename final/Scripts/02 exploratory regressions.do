u "P:\svo\20250806 devecon\Data\prepared_data", replace

* logit followed_lime_1all treated i.program, or // basic regression


logit followed_lime_1all 1.treated 1.treated#c.num_messages i.program, or // dose response


logit followed_lime_1all 1.treated 1.treated#(c.age_decades c.age_squared) age_decades age_squared  i.program,  // nonlinear age response

logit followed_lime_1all 1.treated 1.treated#i.female_b#(c.age_decades c.age_squared) age_decades age_squared 1.female_b i.program,  // nonlinear age response

logit followed_lime_1all 1.treated female_b large_shamba_b c.age_decades c.age_squared i.program
