# HEOR_RWE_Atrial_Fibrillation_Patients
 The key components of the project, including the focus on Real-World Data (RWD), Health Economics and Outcomes Research (HEOR), and the detailed steps involved in data extraction, transformation, cohort selection, dataset creation, and analysis report generation.


# Tasks To Do:

# Task A: Convert all CSV File into SAS Dataset and then, XPT Files

Keep all variable in character except for Date/Date-Time variables.

Input: CSV file

Output: SAS Dataset

QA: Using Proc COMPARE of SAS Datasets

# Task B: Create Analysis Datasets (Cohort selection dataset and Other Analysis Variables)

Refer Specification Excel sheet for list of dataset and derivation rules to create.

Cohort Dataset

trt_pattern Dataset -– See specification

HRU dataset - – See specification

OS Dataset - – See specification

Vital_Sign_Analysis datasets – See specification


Input: XPT File Provided (Don't use one you created)

Output: SAS Datasets (SAS7BDAT) 

QA: Using Proc COMPARE


# Task C: Analysis tables

Refer Mock Shell Document for list of reports to create.


Input: Analysis ready SAS Dataset (with cohort records only)

Output: Reports in PDF/RTF

QA: Using manual check of numbers
