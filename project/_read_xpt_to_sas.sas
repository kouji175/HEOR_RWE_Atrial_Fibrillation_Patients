
*********************************************************
Code to Convert XPT to SAS7badat File
*********************************************************;

*--------------------------
*NOTE: Update the paths;
*--------------------------;
*File Location of Provided XPT File ;
%let Path=/home/abc.xyz/my_shared_file_links/kamlesh.pharmaci/ehr/updated_sas;
*File Location to save datasets/can be same or different ;
%let sasPath=/home/abc.xyz/my_shared_file_links/kamlesh.pharmaci/ehr/updated_sas;

%let file=analysis_ds;*File Name of EHR XPT File;

****Dont Change Code Below;

/* Create transport file from SAS dataset */
filename xptfile  "&path./&file..xpt";
libname sasfile  "&sasPath.";

*  XPT to SAS - ALL Together;
*- Get all EHR Data in work Library
OR
- Save in some permenent library and then use from there;

Proc cimport lib=sasPath infile=xptfile;
Select allergy condition encounter lab location medication 
patient practitioner procedure vital_sign ; * dataset name;
Run;
