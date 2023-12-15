#Specification

#Part 1
********************************************************
Step 1: Cohort Selection - Record Selections
********************************************************;
Take Index Date as 1st Prescription Date i.e. Request Date from Medication dataset.
Study Pop: Atrial Fibrillation ICD10 Code initial 3 characters: "I48"
-          Patients who has Atrial Fibrillation (ICD10 Code initial 3 characters: "I48")
-          AF occurred between '1Jan2007' and '1Jan2019'
-          Keep patient who are treated with below drugs and create cohort variable based on below.
-          Treated with one of three treatment groups in medication datasets
o   Cohort="NOAC" (There are 3 drugs in this cohort)
§  APIXABAN: NDC Code in (3089421 636297747) OR medication_name contains "APIXABAN"
§  DABIGATRAN: NDC Code in (5970108) OR medication_name contains "DABIGATRAN"
§  RIVAROXABAN: NDC Code in (50458577) OR medication_name contains "RIVAROXABAN"
o   Cohort =”WARFARIN”
§  WARFARIN: NDC Code in (31722327) OR medication_name contains "WARFARIN”
o   Cohort =”ASPIRIN”
§  ASPIRIN: NDC Code in (31722327) OR medication_name contains "ASPIRIN”
-          Request_Date is prescription Date
-          Select only patient with selected drugs + Specific Timeframe Records as per SAP
-          To Check if any patient falls in two different cohort category or not;
-          Dont need dup records as deriving cohorts;
-          Dataset has Cohort variable on which we would perform all analysis.
-          Still Inclusion Criteria & Exclusion Criteria needs to be applied
o   Inclusion Criteria:
§  Inclusion Criteria 1: Age > 18
§  Inclusion Criteria 2: Condition of AF (ICD10 Code initial 3 characters: "I48")
§  Inclusion Criteria 3: Taken specific medications etc.
§  Exclusion Criteria 1: Fracture Exclusion (
M81 - Age-related osteoporosis without current pathological fracture &
I97 - Postprocedural cardiac insufficiency)
§  Exclusion Criteria 2: Fluoroscopy of Heart – Exclude (Procedure Codes: B215YZZ B2151ZZ B2151ZZ )
#Part 2
Dataset	#	Variable	Type	Len	Derivation_Notes
Cohort	1	patient_id	Char	30	Select Patient_ID from DS.Patient as per Selection - Inclusion and Exclusion Criteria.
Cohort	2	gender	Char	6	From Patient Dataset
Cohort	3	death_date	Num	8	From Patient Dataset
Cohort	4	death_flag	Num	8	From Patient Dataset
Cohort	5	race	Char	41	From Patient Dataset
Cohort	6	cohort	Char	20	From Medication:
If ndc in (3089421 636297747) OR Index(upcase(medication_name), "APIXABAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 5970108) OR Index(upcase(medication_name), "DABIGATRAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 50458577) OR Index(upcase(medication_name), "RIVAROXABAN") then do;
Cohort="NOAC"; CohortN=1; end;
else If ndc in ( 31722327) OR Index(upcase(medication_name), "WARFARIN") then do;
Cohort="Warfarin"; CohortN=2; end;
else If ndc in (2802100) OR Index(upcase(medication_name), "ASPIRIN") then do;
Cohort="Aspirin"; CohortN=3; end;
Cohort	7	CohortN	Num	8
Cohort	8	cohort1n	Num	8	If cohortn in (1) then 1 else 2
Cohort	9	Index_Date	Num	8	From Medication.Request_Date
Cohort	10	birth_date	Num	8	From Patient Dataset
Cohort	11	age	Num	8	Calculate it - Birth_Date and Index_Date
Cohort	12	STROK	Num	8	See Appendix (Table 1). If ICD10 codes are found then 1 for those patient ID, else missing.
Cohort	13	Bleed	Num	8	See Appendix (Table 2). If ICD10 codes are found then 1 for those patient ID, else missing.
Cohort	14	AgeCat	Char	10	65=< to 75, <65, 75< from Age variable.
Cohort	15	CHA2DS2	Num	8	See Appendix (Table 3) (NOTE: Check Value of STROKE and update STROKE value for calculation of this score)
Cohort	16	HASBLED	Num	8	See Appendix (Table 4)
Cohort	17	Year	Num	8	Year of diagnosis from Index date
Dataset	#	Variable	Type	Len	Derivation_Notes
HRU	1	patient_id	Char	30	From Cohort : Select Records from eligible cohort dataset
HRU	2	
encounter_type
Char	20	encounter
HRU	3	cohort	Char	20	From Cohort
HRU	4	CohortN	Num	8	From Cohort
HRU	5	cohort1n	Num	8	From Cohort
Dataset	#	Variable	Type	Len	Derivation_Notes
OS	1	patient_id	Char	30	From Cohort : Select Records from eligible cohort dataset
OS	2	cohort	Char	20	From Cohort
OS	3	CohortN	Num	8	From Cohort
OS	4	start_date	Num	8	From Cohort - Index Date
OS	5	CNSR	Num	8	If death_date not missing then do;
CNSR=0; Event=1; ADT=death_date; EVNTDESC="Death"; end;
Else If death_date eq missing and last_followup ne . then do;
CNSR=1; Event=0; ADT=last_followup; EVNTDESC="No Event: Censored at Last Activity Date"; end;
Else If death_date eq . and last_followup eq . then do;
CNSR=1;Event=0;ADT=index_date;EVNTDESC="No Event: Censored at Index Date"; end;
OS	6	ADT	Num	8
OS	7	EVNTDESC	Char	5
OS	8	AVAL	Num	8	ADT-Start_date+1 /(365/12)
OS	9	
last_followup
Num	8	Select maximum date from all date values of all dataset by subject
Dataset	#	Variable	Type	Len	Derivation_Notes
VITAL_SIGN_ANALYSIS
1	patient_id	Char	30	From Cohort : Select Records from eligible cohort dataset
VITAL_SIGN_ANALYSIS
2	loinc	Char	10	From Vital Sign: Records .z <index_date-30 < vital_date AND loinc in ('8462-4', '8480-6', '8867-4')
VITAL_SIGN_ANALYSIS
3	cohort1n	Num	8	From Cohort
VITAL_SIGN_ANALYSIS
4	Base	Num	8	Any Vital Sign records falls in -30 Days Before and 30 days After of Index Date of AF, then it will be considered as Baseline Value. If any multiple records then closer to Index Date will be selected.
VITAL_SIGN_ANALYSIS
5	vital_date	Num	8	From Vital Sign: Records .z <index_date-30 < vital_date
VITAL_SIGN_ANALYSIS
6	death_date	Num	8	From Cohort
VITAL_SIGN_ANALYSIS
7	Post_Base	Num	8	*Post-Baseline;
Select Post-Baseline if-
- Last available non-missing record after Index Date AND
- Before Death Date (if any death date)
VITAL_SIGN_ANALYSIS
8	CHG	Num	8	CHG=Post_base-base;
Dataset	#	Variable	Type	Len	Derivation_Notes
TRT_PATTERN
1	patient_id	Char	30	From Cohort : Select Records from eligible cohort dataset
TRT_PATTERN
2	Num_Presc	Num	8	count of encounter_id from medication
TRT_PATTERN
3	Num_Cat	Num	8	count of distinct category
Categories are creates as per Appendix - "Table 6: Baseline Medication"
TRT_PATTERN
4	cohort	Char	20	From Cohort
TRT_PATTERN
5	CohortN	Num	8	From Cohort
TRT_PATTERN
6	cohort1n	Num	8	From Cohort
