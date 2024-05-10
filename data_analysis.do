// Set up global paths
global repo "https://raw.githubusercontent.com/PRASADJHSPH/project/main/"
global nhanes "https://wwwn.cdc.gov/Nchs/Nhanes/"

// Import NHANES survey data
import sasxport5 "${nhanes}1999-2000/DEMO.XPT", clear

// Run the followup do file from the GitHub repository
do ${repo}followup.do

// Save the followup data locally
save followup, replace

// Merge the follow-up data with NHANES survey data
merge 1:1 seqn using followup, nogen
save survey_followup, replace

// Remove unnecessary files
rm followup.dta

// Import Health and Nutrition Examination Survey questionnaire data
import sasxport5 "${nhanes}1999-2000/HUQ.XPT", clear
tab huq010

// Merge the health questionnaire data with the survey and follow-up data
merge 1:1 seqn using survey_followup, nogen keep(matched)
save week7, replace

// Clean up variables and set survival time variable
gen years = permth_int / 12
replace huq010 = . if huq010 == 9
label define huq 1 "Excellent" 2 "Very Good" 3 "Good" 4 "Fair" 5 "Poor"
label values huq010 huq

// Set the survival analysis data
stset years, failure(mortstat)

// Kaplan-Meier survival estimates by self-reported health
sts graph, by(huq010) fail per(100) ylab(0(20)80, format(%2.0f)) xlab(0(5)20) tmax(20) ti("Self-Reported Health and Mortality") legend(order(5 4 3 2 1) lab(1 "Excellent") lab(2 "Very Good") lab(3 "Good") lab(4 "Fair") lab(5 "Poor") ring(0) pos(11))
graph export nonpara.png, replace 

// Cox proportional hazards model
stcox i.huq010, basesurv(s0)
matrix mat = r(table)
matrix list mat
matrix mat = mat'
svmat mat
preserve
keep mat*
rename (mat1 mat2 mat3 mat4 mat5 mat6 mat7 mat8 mat9)(b se z p ll ul df crit eform)
graph export semipara_unadj.png, replace 
graph save semipara_unadj.gph, replace 
restore

// Export combined graphs
graph combine semipara_unadj.gph, ycommon ti("Hazard Ratio, 95%CI") 
graph export unadj_adj.png, replace 

// Cleanup and conclude
clear
di "Data processing and analysis complete."
