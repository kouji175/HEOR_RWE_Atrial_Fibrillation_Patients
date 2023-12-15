libname input "/home/u63531299/project";
libname output "/home/u63531299/output";
libname taskc "/home/u63531299/taskc";
libname ands "/home/u63531299/taskb_r";
libname taskbr "/home/u63531299/task_b_r1";
options mprint mprintnest mlogic mlogicnest symbolgen;
*******************************************************************
************************TASKA**************************************
*********************************************************;

%macro iptcsv(file);
%let path=/home/u63531299/project/&file..csv;
PROC IMPORT DATAFILE="&path"
	DBMS=CSV
	OUT=WORK.IMPORT
	replace;
	guessingrows=max;
	GETNAMES=YES;
RUN;
%global outfile infile;
%let outfile=%sysfunc(catx( ,output.,&file));
%let infile=%sysfunc(catx( ,input.,&file));
%mend;

%iptcsv(allergy);
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id:;
run;
proc compare base=&infile compare=&outfile;
run;


%iptcsv(condition);
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id:;
run;
proc compare base=&infile compare=&outfile;
run;


%iptcsv(encounter);
options datestyle=mdy;
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id:;
run;
proc compare base=&infile compare=&outfile;
run;

%iptcsv(lab);
data &outfile;
length loinc $ 10;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id:;
run;
proc compare base=&infile compare=&outfile;
run;

%iptcsv(location);
data &outfile;
set import;
run;
proc compare base=&infile compare=&outfile;
run;


%iptcsv(medication);
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id: VAR:;
run;
proc compare base=&infile compare=&outfile;
run;


%iptcsv(patient);
data &outfile;
set import(rename=(patient_id=id2));
patient_id =left(input(id2,$30.));
drop id: VAR:;
run;
proc compare base=&infile compare=&outfile;
run;

%iptcsv(practitioner);
data &outfile;
set import;
run;
proc compare base=&infile compare=&outfile;
run;

%iptcsv(procedure);
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
drop id:;
run;
proc compare base=&infile compare=&outfile;
run;

%iptcsv(vital_sign);
data &outfile;
set import(rename=( encounter_id=id1 patient_id=id2 loinc=id3));
encounter_id=left(input(id1,$30.));
patient_id =left(input(id2,$30.));
loinc=left(input(id3,$10.));
drop id: loinc1 VAR11;
run;
proc compare base=&infile compare=&outfile;
run;

data mydata;
  infile '/home/u63531299/project/vital_sign.csv' dsd dlm=',' truncover firstobs=2; 
  length encounter_id $30 patient_id $30 loinc $10 loinc_description $35 component_id $1 units $9 data_source $3;
  input encounter_id $ patient_id $ component_id $
        loinc $ loinc_description $
        vital_date : mmddyy10. value : best32. units $ data_source $ loinc1 $;
  informat loinc_description $35. component_id $1. vital_date mmddyy10. value best32. units $9. data_source $3.;
  format loinc_description $35. component_id $1. vital_date mmddyy10. value best12. units $9. data_source$3.;
  drop loinc1;
run;

proc compare base=input.vital_sign compare=mydata;
run;


libname xportout xport '/home/u63531299/xpt/allergy.xpt';
Filename tranfile '/home/u63531299/xpt/allergy.xpt';
Proc cport data=output.allergy file=tranfile;
Run;



%let xpt_dir = /home/u63531299/xpt/;

proc sql noprint;
   select memname into :table_list separated by ' '
   from dictionary.tables
   where libname = 'OUTPUT';
quit;
%put &table_list;

%macro convert_to_xpt;
   %local i table_name xpt_file;
   %let i = 1;
   %do %while (%scan(&table_list, &i) ne %str());

      %let table_name = %scan(&table_list, &i);

      %let xpt_file = &xpt_dir.&table_name..xpt;

      filename tranfile "&xpt_file";
      proc cport data=OUTPUT.&table_name file=tranfile;
      run;

      %put Converted &table_name to &xpt_file;

      %let i = %eval(&i + 1);
   %end;
%mend;

%convert_to_xpt;

*******************************************************************
************************TASKB**************************************
*******************************************************************;
proc sql;
create table inclu_1 as
select distinct patient_id
from taskbr.condition
where code like 'I48%';
quit;

proc sql;
create table exclu_1 as
select distinct patient_id
from taskbr.condition
where code like 'M81%' or code like 'I97%';
quit;

proc sql;
create table exclu_2 as
select distinct patient_id
from taskbr.procedure
where code in ('B215YZZ' 'B2151ZZ' 'N0711' 'N0715' 'N1711' 'N1715' 'N1721' 'N1725' 'N2070'
'N2072' 'N2077' 'N2710' 'N2712' 'N2717' 'N3710' 'N3712' 'N3717' 'N3720' 'N3722' 'N3727' 'N4710'
'N4712' 'N4717' 'N4720' 'N4722' 'N4727' 'M5880' 'M6540' 'M6542' 'M6545' 'M6547' 'M6511');
quit;


/*cohort*/
proc sort data=taskbr.medication;
	by patient_id descending request_date;
run;

data medication_1;
	set taskbr.medication;
	retain pre_date;
	by patient_id descending request_date;
    if first.encounter_id=1 then
		pre_date=request_date;

	if request_date=. then
		request_date=pre_date;
	where request_date is not missing;
run;

data patient_1;
	set taskbr.patient;
	where birth_date is not missing;
run;

proc sort data=patient_1;
	by patient_id;
run;

data mp;
	length AgeCat $ 10 cohort $20.;
	merge medication_1(rename=(request_date=index_date) in=m) 
		patient_1(in=p);
	by patient_id;
	gender=propcase(gender);
	if gender="Female" then _C8=1;
	%let regex = Bromfenac|Celecoxib|Diclofenac|Etodolac|Fenoprofen|Flurbiprofen|Ibuprofen|Indomethacin|Ketoprofen|Ketorolac|Naproxen|Meclofenamate|Mefenamic acid|Meloxicam|Nabumetone|Oxaprozin|Piroxicam|Sulindac|Tolmetin|Aspirin|Clopidogrel|Prasugrel|Ticlopidine|Cilostazol|Abciximab|Tirofiban|Dipyridamole|Ticagrelor;

	/* 使用 PRXMATCH 函数进行匹配 */
	if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		_H8=1;

	If ndc in (3089421 636297747) OR Index(upcase(medication_name), "APIXABAN")>0 
		then
			do;
			Cohort="NOAC";
			CohortN=1;
			Cohort1n=1;
		end;
	else If ndc in (5970108) OR Index(upcase(medication_name), "DABIGATRAN")>0 then
		do;
			Cohort="NOAC";
			CohortN=1;
			Cohort1n=1;
		end;
	else If ndc in (50458577) OR Index(upcase(medication_name), "RIVAROXABAN")>0 
		then
			do;
			Cohort="NOAC";
			CohortN=1;
			Cohort1n=1;
		end;
	else If ndc in (31722327) OR Index(upcase(medication_name), "WARFARIN")>0 then
		do;
			Cohort="Warfarin";
			CohortN=2;
			Cohort1n=2;
		end;
	else If ndc in (2802100) OR Index(upcase(medication_name), "ASPIRIN")>0 then
		do;
			Cohort="Aspirin";
			CohortN=3;
			Cohort1n=2;
		end;
	if m and p and patient_id ne ' ';
	Age=(index_date-birth_date+1)/365;
	
	Year=year(index_date);

	if Age>18;
	if Age<65 then
		AgeCat='<65';
	else if Age<=75 then do;
		AgeCat='65=< to 75';
		_C7=1;
		_H7=1;end;
	else do;
		AgeCat='75<';
		_C3=2;
		_H7=1;
		end;
		
	keep Year Age _: AgeCat Cohort Cohort1n CohortN birth_date
		death_date death_flag gender index_date medication_name
		patient_id race;
run;	

proc means data=mp mean;
class patient_id;
var _:;
output out=mp_1 mean=;
run;
data mp_2;
set mp;
by patient_id;
if Cohort ne '';
drop _:;
run;

data mp_3;
merge mp_1(in=a) mp_2(in=b);
if a and b;
by patient_id;
drop _Type_ _freq_;
run;

proc sort data=mp_3 nodup;
by patient_id;
run;

data condition_1;
	set taskbr.condition;
	
	if code in: ('I63' 'I693' 'G459' 'I69' 'G45') then do;
		STROK=2;
		_C5=2;
		_H4=1;
		end;
	else
		STROK=.;

	if code in: ("I60" "I61" "I62" "I690" "I691" "I692" "S064" "S065" "S066" "S068" 
		"I850" "I983" "K2211" "K226" "K228" "K250" "K252" "K254" "K256" "K260" "K262" 
		"K264" "K266" "K270" "K272" "K274" "K276" "K280" "K282" "K284" "K286" "K290" 
		"K3181" "K5521" "K625" "K920" "K921" "K922" "D62" "H448" "H3572" "H356" 
		"H313" "H210" "H113" "H052" "H470" "H431" "I312" "N020" "N021" "N022" "N023" 
		"N024" "N025" "N026" "N027" "N028" "N029" "N421" "N831" "N857" "N92" "N923" 
		"N930" "N938" "N939" "M250" "R233" "R040" "R041" "R042" "R048" "R049" "T792" 
		"T810" "N950" "R310" "R311" "R318" "R58" "T455" "Y442" "D683") then do;
			Bleed=1;
			_H5=1;
			end;
	Else
		Bleed=.;
	if code =: 'I50' then _C1=1;
	if code in: ('I10' 'I11' 'I12' 'I13' 'I14' 'I15') then _C2=1;
	if ('E10' <=: code <=: 'E14') then _C4=1;
	if code in: ('I21' 'I252' 'I70' 'I71' 'I72' 'I73') then _C6=1;
	if code in: ('I10' 'I11' 'I12' 'I13' 'I14' 'I15') then _H1=1;
	if code in: ('N183' 'N184') then _H2=1;
	if code in: ( 'B15' 'B16' 'B17' 'B18' 'B19' 'C22' 'D684' 'I982' 
	'I983' 'K70' 'K71' 'K72' 'K73' 'K74' 'K75' 'K76' 'K77' 'Z944') then _H3=1;
	if code in:('E244' 'F10' 'G312' 'G621' 'G721' 'I426' 'K292' 'K70' 'K860'
	 'O354' 'P043' 'Q860' 'T510' 'X45' 'X65' 'Y15' 'Y90' 'Y91' 'Z502' 'Z714' 'Z721') then _H9=1;
	keep patient_id STROK Bleed _:;
run;

proc sort data=condition_1;
	by patient_id;
run;

data mpc;
	merge mp_3(in=mp) condition_1(in=c);

	if mp and c;
	by patient_id;
	run;
	
proc means data=mpc ;
class patient_id;
var _: STROK Bleed;
output out=mpc_1 mean=;
run;

data mpc_2;
  set mpc_1;
  CHA2DS2 = sum(of _C:);
  HASBLED = sum(of _H:);
  keep patient_id CHA2DS2 HASBLED STROK Bleed;
run;

proc sql;
create table mpc_3 as
select * from mpc_2
where patient_id in (select patient_id from inclu_1) 
and patient_id not in (select patient_id from exclu_1)
and patient_id not in (select patient_id from exclu_2);
quit;

data mpc_4;
	length cohort $20.;
	merge mp_3(in=a) mpc_3(in=b);
	by patient_id;
	if a and b;
	race = tranwrd(race, 'or', 'Or');
	drop medication_name _:;
run;
proc datasets library=work;
  modify mpc_4;
  attrib gender race  format=; 
 attrib gender race  informat=;
run;
proc sql;
  create table cohort as
  select   patient_id, gender, death_date, death_flag, race, cohort, CohortN, cohort1n,Index_Date, birth_date, age, STROK, Bleed, AgeCat, CHA2DS2, HASBLED, Year
  from mpc_4; 
quit;
proc sort data=cohort nodupkey;
by patient_id;
run;
proc compare base=ands.cohort compare=cohort;
run;
/*HRU*/
proc sql;
create table encou as
select *
from taskbr.encounter
where patient_id in (select patient_id from cohort);
quit;
proc sort data=encou out=encou_1;
by patient_id;
run;

data hru;
merge encou_1(keep=patient_id encounter_type) cohort(keep=patient_id cohort CohortN cohort1n);
by patient_id;
run;
proc compare base=ands.hru compare=hru;
run;
/*OS*/
data os_1(keep=patient_id cohort CohortN index_date death_date rename=(index_date=start_date));
set cohort;
run;

proc sort data=taskbr.condition;
by patient_id;
run;
proc sort data=taskbr.encounter;
by patient_id;
run;
proc sort data=taskbr.lab;
by patient_id;
run;
proc sort data=taskbr.medication;
by patient_id;
run;
proc sort data=taskbr.procedure;
by patient_id;
run;
proc sort data=taskbr.vital_sign;
by patient_id;
run;
proc sort data=taskbr.patient;
by patient_id;
run;
data os_date_1;
merge os_1(keep=patient_id in=o) taskbr.lab(keep=patient_id result_date in=l) taskbr.encounter(keep=patient_id encounter_end_date in=e)
taskbr.condition(keep=patient_id condition_date in=c)
taskbr.medication(keep=patient_id filled_date in=m) taskbr.procedure(keep=patient_id procedure_date in=p)
taskbr.vital_sign(keep=patient_id vital_date in=v)
taskbr.patient(keep=patient_id death_date in=p);
by patient_id;
if o;
_pro_date=input(substr(put(procedure_date,e8601dt.),1,10),yymmdd10.);
_econ_date=input(substr(put(encounter_end_date,e8601dt.),1,10),yymmdd10.);
_result_date=input(substr(put(result_date,e8601dt.),1,10),yymmdd10.);
_condition_date=condition_date;
_filled_date=filled_date;
_vital_date=vital_date;
_death_date=death_date;
date=max(of _:);
run;
proc means data=os_date_1 max;
by patient_id;
var date;
output out=os_date_2 max=;
run;
data os;
merge os_1 os_date_2(keep=patient_id date rename=(date=last_followup) );
by patient_id;
run;


/*vital sign*/
proc sort data=taskbr.vital_sign;
by patient_id;
run;
data vital_1;
merge taskbr.vital_sign cohort(keep=patient_id index_date cohort1n death_date in=c);
if c and loinc in ('8462-4' '8480-6' '8867-4') and index_date-30<vital_date;
by patient_id;
run;
proc sort data=vital_1;
by patient_id loinc vital_date;
run;
data vital_2;
set vital_1;
by patient_id loinc vital_date;
retain n;
if first.loinc then n=0;
n+1;
run;
proc transpose data=vital_2 out=vital_2_l prefix=_;
id n;
var vital_date;
by patient_id loinc index_date;
run;
data vital_base(drop=i diff min_diff _:);
set vital_2_l(Drop=_name_);
array date_array(*) _:;
min_diff = abs(date_array[1] - index_date);
Base_date = date_array[1];
do i = 2 to dim(date_array);
  diff = abs(date_array[i] - index_date);
  if diff < min_diff and diff ne . then do;
    min_diff = diff;
    Base_date = date_array[i];
  end;
end;
if min_diff<=30;
format Base_date mmddyy10.;
run;
proc sort data=vital_base;
by patient_id loinc ;
run;
data vital_sign;
merge vital_base vital_2;
retain Base;
by patient_id loinc;
if Base_date=vital_date then Base=value;
if last.loinc then do;
Post_Base=value;
CHG=Post_base-Base; 
output;
end;
format Post_Base Base Best12.;
keep  patient_id loinc Cohort1n Base vital_date death_date Post_Base CHG;
run;


proc compare base=ands.vital_sign_analysis compare=vital_sign;
run;

/*TRT_PATTERN*/
data medication_cat;
length Cat $30;
set taskbr.medication;
%let regex = Bromfenac|Celecoxib|Diclofenac|Etodolac|Fenoprofen|Flurbiprofen|Ibuprofen|Indomethacin|Ketoprofen|Ketorolac|Naproxen|Meclofenamate|Mefenamic acid|Meloxicam|Nabumetone|Oxaprozin|Piroxicam|Sulindac|Tolmetin;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='NSAIDs';
%let regex = Aspirin|Clopidogrel|Prasugrel|Ticlopidine|Cilostazol|Abciximab|Tirofiban|Dipyridamole|Ticagrelor;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='Antiplatelets';
%let regex = Omeprazole|Pantoprazole|Lansoprazole|Rabeprazole|Esomeprazole|Dexlansoprazole;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='PPI';
%let regex = Cimetidine|Ranitidine|Famotidine|Nizatidine|Roxatidine|Lafutidine;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='H2-receptor antagonists';
%let regex = Quinidine|Procainamide|Mexiletine|Propafenone|Flecainide|Amiodarone|Bretylium|Dronedarone|Propranolol|Atenolol|Esmolol|Verapamil|Diltiazem|Sotalol;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='Antiarrhythmics';
%let regex =Digoxin ;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='Digoxin';
%let regex = Atorvastatin|Fluvastatin|Lovastatin|Pitavastatin|Pravastatin|Roxuvastatin|Simvastatin;
if prxmatch("/&regex/i", upcase(medication_name)) > 0 then
		Cat='Statins';
run;



proc sql;
create table trt_1 as
select c.patient_id,count(encounter_id) as Num_presc, count(distinct Cat) as Num_Cat,cohort,CohortN,cohort1n
from medication_cat as m
right join cohort as c on c.patient_id=m.patient_id
group by c.patient_id;
quit;

proc sort data=trt_1 out=trt_pattern nodup;
by patient_id;
run;

proc compare base=ands.trt_pattern compare=trt_pattern;
run;
*******************************************************************
************************TASKC**************************************
*******************************************************************;
/*Demographic and Baseline Characteristics Summary*/
data demog;
length CHA $ 10. HASB $10.;
set ands.cohort;
if CHA2DS2 <= 2 then CHA='0-2';
else if CHA2DS2 = 3 then CHA='3';
else if CHA2DS2 = 4 then CHA='4';
else if CHA2DS2 >= 5 then CHA='>=5';
if HASBLED <=2 then HASB='0-2';
else if HASBLED >=3 then HASB='>=3';
year1=put(year(index_date),4.);
keep patient_id gender race Cohort AgeCat age CHA2DS2 HASBLED CHA HASB year1;
run;

data demo_1;
set demog;
output;
cohort="All";
output;

proc freq data=demo_1;
table CHA;
run;

data demo_2;
length cohort1 $10.;
set demo_1;
if cohort="Aspirin" then do;
cohort1="Aspirin";
ORD=1;
end;
if cohort="Warfarin" then do;
cohort1="Warfarin";
ORD=2;
end;
if cohort="NOAC" then do;
cohort1="NOAC";
ORD=3;
end;
if cohort="All" then do;
cohort1="All";
ORD=4;
end;

proc sql noprint;
select count(distinct patient_id) into :N1 - :N4 
from demo_2
group by ORD 
order by ORD;
quit;
%put &N1 &N2 &N3 &N4;

/*gender*/
proc freq data=demo_2 noprint;
table gender*cohort1/out=gender (drop=percent);
title 'gender Freq in Cohort';
run;

data gen_1;
length Var $40.;
set gender;
if gender="Male" then do;
Var="Male";
OD=1;
end;
if gender="Female" then do;
Var="Female";
OD=2;
end;
drop gender;
run;

proc sort data=gen_1;
by OD;
run;
/*race*/
proc freq data=demo_2 noprint;
table race*cohort1/out=race (drop=percent);
title 'Race Freq in Cohort';
run;

data race_1;
length Var $70.;
set race;
Var=race;
select(race);
    when ('White') OD = 1;
    when ("Black Or African American") OD=2;
    when ("Asian") OD=3;
    when ("American Indian Or Alaska Native") OD=4;
    when ("Native Hawaiian Or Other Pacific Islander") OD=5;
    when ("Other Race") OD=6;
    when ("Unknown") OD=7;
end;
drop race;
run;
proc sort;
by OD;
run;
/*CHA2DS2*/
proc freq data=demo_2 noprint;
table CHA*cohort1/out=CHA (drop=percent);
title 'CHA2DS2 Freq in Cohort';
run;

data CHA_1;
length Var $70.;
set CHA;
Var=CHA;
select(CHA);
    when ('0-2') OD = 1;
    when ("3") OD=2;
    when ("4") OD=3;
    when (">=5") OD=4;
end;
drop CHA;
run;
proc sort;
by OD;
run;

/*HASBLED*/
proc freq data=demo_2 noprint;
table HASB*cohort1/out=HASB (drop=percent);
title 'HASB Freq in Cohort';
run;

data HASB_1;
length Var $70.;
set HASB;
Var=HASB;
select(HASB);
    when ('0-2') OD = 1;
    when (">=3") OD=2;
end;
drop HASB;
run;
proc sort;
by OD;
run;

/*AgeCat*/
proc freq data=demo_2 noprint;
table AgeCat*cohort1/out=AgeCat (drop=percent);
title 'AgeCat Freq in Cohort';
run;

data AgeCat_1;
length Var $70.;
set AgeCat;
Var=AgeCat;
select(AgeCat);
    when ('<65') OD = 1;
    when ("65=< to 75") OD=2;
    when ("75<") OD=3;
end;
drop AgeCat;
run;
proc sort;
by OD;
run;

/*Year*/
proc freq data=demo_2 noprint;
table year1*cohort1/out=year1 (drop=percent);
title 'Year Freq in Cohort';
run;

data Year_1;
length Var $70.;
set year1;
Var=year1;
select(year1);
    when ('2020') OD = 1;
    when ("2019") OD=2;
    when ("2018") OD=3;
end;
drop year1;
run;
proc sort;
by OD;
run;

/* Transpose and count and percentage*/
%macro tran(name);
proc transpose data=&name._1 out=&name._2;
by OD Var;
ID cohort1;
var count;
proc stdize data=&name._2 out=&name._3 reponly missing=0;
run;
data &name._4;
length ASPIRIN_ WARFARIN_ NOAC_ ALL_ $70.;
set &name._3;
if Aspirin=. then ASPIRIN_ ="0 (0)";
else if Aspirin=&N1 then Aspirin_=put(Aspirin,3.)||"(100%)";
else ASPIRIN_=put(Aspirin,3.)||"("||put(Aspirin/&N1*100,4.1)||")";

if Warfarin=. then WARFARIN_ ="0 (0)";
else if Warfarin=&N2 then WARFARIN_=put(Warfarin,3.)||"(100%)";
else WARFARIN_=put(Warfarin,3.)||"("||put(Warfarin/&N2*100,4.1)||")";

if NOAC=. then NOAC_ ="0 (0)";
else if NOAC=&N3 then NOAC_=put(NOAC,3.)||"(100%)";
else NOAC_=put(NOAC,3.)||"("||put(NOAC/&N3*100,4.1)||")";

if All=. then All_ ="0 (0)";
else if All=&N4 then All_=put(All,3.)||"(100%)";
else All_=put(All,3.)||"("||put(All/&N4*100,4.1)||")";
run;
%mend;
%tran(gen);
%tran(race);
%tran(CHA);
%tran(HASB);
%tran(AgeCat);
%tran(year);
 /*add name of cat vars*/
data dummy;
length Var $70.;
Var='Gender (%)';
run;

data gen_5;
set dummy gen_4;
ORD=2;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

data dummy;
length Var $70.;
Var='Race (%)';
run;

data race_5;
set dummy race_4;
ORD=3;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

data dummy;
length Var $70.;
Var='';
run;

data CHA_5;
set dummy CHA_4;
ORD=5;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

data dummy;
length Var $70.;
Var='';
run;

data HASB_5;
set dummy HASB_4;
ORD=7;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

data dummy;
length Var $70.;
Var='Age Categorization (%)';
run;

data AgeCat_5;
set dummy CHA_4;
ORD=8;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

data dummy;
length Var $70.;
Var='Year of Diagnosis of AF';
run;

data year_5;
set dummy year_4;
ORD=9;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

/*Stack datasets*/
data category (drop=_:);
set gen_5 race_5 CHA_5 HASB_5 AgeCat_5 year_5;
run;

/*print*/
proc print data=category;
ID Var;
Var ASPIRIN_ WARFARIN_ NOAC_ ALL_;
title "Clinic Summary of Numerical Variables";
run;
/*summary of age */
proc sort data=demo_2;
by cohort1;
run;
proc means noprint data=demo_2 maxdec=0 n mean median min max stddev;
by cohort1;
Var Age;
output out=summary_age(drop=_freq_) mean(Age)=mean n(Age)=n
median(Age)=median min(Age)=min max(Age)=max stddev(Age)=std;
run;
data summary_age_1;
set summary_age;
mean=compress(put(mean,4.));
median=compress(put(median,4.));
n=compress(put(n,4.));
mnmx=compress(put(min,4.))||' ,'||put(max,4.0);
std=compress(put(std,4.));
drop min max _:;
run;
proc transpose data=summary_age_1 out=summary_age_2 name=Var;
ID cohort1;
var n mean median mnmx std;
run;

data summary_age_3;
Length Var ASPIRIN_ WARFARIN_ NOAC_ ALL_ $70.;
set summary_age_2;
ASPIRIN_=Aspirin;
WARFARIN_=Warfarin;
NOAC_=NOAC;
ALL_=All;
if Var="n" then do;
Var="N";
OD=1;
end;
if Var="mean" then do;
Var="Mean";
OD=2;
end;
if Var="median" then do;
Var="Median";
OD=3;
end;
if Var="mnmx" then do;
Var="Min, Max";
OD=4;
end;
if Var="std" then do;
Var="Standard Deviation";
OD=5;
end;
drop _: Aspirin Warfarin NOAC All;
run;
proc sort;
by OD;
run;

data dummy;
length Var $70.;
Var="Age";
run;

data summary_age_4;
set dummy summary_age_3;
ORD=1;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

/*summary of CHA2DS2 */
proc sort data=demo_2;
by cohort1;
run;
proc means noprint data=demo_2 maxdec=0 n mean median min max stddev;
by cohort1;
Var CHA2DS2;
output out=summary_CHA2DS2(drop=_freq_) mean(CHA2DS2)=mean stddev(CHA2DS2)=std;
run;
data summary_CHA2DS2_1;
set summary_CHA2DS2;
MeanSD=put(mean,4.2)||'('||put(std,4.2)||')';
drop mean std _:;
run;
proc transpose data=summary_CHA2DS2_1 out=summary_CHA2DS2_2 name=Var;
ID cohort1;
var MeanSD;
run;

data summary_CHA2DS2_3;
Length Var ASPIRIN_ WARFARIN_ NOAC_ ALL_ $70.;
set summary_CHA2DS2_2;
ASPIRIN_=Aspirin;
WARFARIN_=Warfarin;
NOAC_=NOAC;
ALL_=All;
if Var="MeanSD" then do;
Var="Mean (SD)";
OD=1;
end;
drop _: Aspirin Warfarin NOAC All;
run;
proc sort;
by OD;
run;

data dummy;
length Var $70.;
Var="CHA2DS2-VASc Score";
run;

data summary_CHA2DS2_4;
set dummy summary_CHA2DS2_3;
ORD=4;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

/*summary of HASBLED */
proc sort data=demo_2;
by cohort1;
run;
proc means noprint data=demo_2 maxdec=0 n mean median min max stddev;
by cohort1;
Var HASBLED;
output out=summary_HASBLED(drop=_freq_) mean(HASBLED)=mean stddev(HASBLED)=std;
run;
data summary_HASBLED_1;
set summary_HASBLED;
MeanSD=put(mean,4.2)||'('||put(std,4.2)||')';
drop mean std _:;
run;
proc transpose data=summary_HASBLED_1 out=summary_HASBLED_2 name=Var;
ID cohort1;
var MeanSD;
run;

data summary_HASBLED_3;
Length Var ASPIRIN_ WARFARIN_ NOAC_ ALL_ $70.;
set summary_HASBLED_2;
ASPIRIN_=Aspirin;
WARFARIN_=Warfarin;
NOAC_=NOAC;
ALL_=All;
if Var="MeanSD" then do;
Var="Mean (SD)";
OD=1;
end;
drop _: Aspirin Warfarin NOAC All;
run;
proc sort;
by OD;
run;

data dummy;
length Var $70.;
Var="HASBLED-VASc Score";
run;

data summary_HASBLED_4;
set dummy summary_HASBLED_3;
ORD=6;
if _n_ gt 1 then Var="^_^_^_^_^_^_"||Var;
run;

/*Stack numeric datasets*/
data numeric;
set summary_age_4 summary_CHA2DS2_4 summary_HASBLED_4;
run;
proc print data=numeric;
var Var ASPIRIN_ WARFARIN_ NOAC_ ALL_;
title "Clinic Summary of Numerical Variables";
run;
/*combine*/
data combine;
set category numeric;
run;
proc sort out=combine_1;
by ORD OD;
run;

/*report*/
option nodate;
ods escapechar="^";
ods pdf file='/home/u63531299/taskc/t-demo_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-demo_heor1.rtf' style=Journal;
title1 "Demographic and Baseline Characteristics Summary";
title2 "Atrial fibrillation Patients received Aspirin, Warfarin and NOAC";
proc report data=combine_1 headline headskip split="|" missing spacing=1 wrap style (HEADER)={just=C}
style (report)=[rules=group frame=hsides];
column (ORD OD Var ASPIRIN_ WARFARIN_ NOAC_ ALL_);
define ORD/ order noprint;
define OD/ order noprint;
define Var/ group " " style (column)=[just=l cellwidth=40%] style(header)=[just=c cellwidth=40%];
define ASPIRIN_/ group "ASPIRIN | (N = &N1)" style (column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define WARFARIN_/ group "WARFARIN | (N = &N2)" style (column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define NOAC_/ group "NOAC | (N = &N3)" style (column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define ALL_/ group "TOTAL | (N = &N4)" style (column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
compute before ORD;
line ' ';
endcomp;
run;
title;
ods pdf close;
ods rtf close;

/*Overall Survival Summary*/
options validvarname=v7 nodate nonumber;

proc freq data=ands.os;
table cohort/ out=freq1_1(drop=PERCENT) nocol nocum nofreq nopercent norow;
table cohort*CNSR/ out=freq1_2 nocol nocum nofreq nopercent norow;
table cohort*CNSR*EVNTDESC/ out=freq1_3(drop=PERCENT where=(CNSR=0)) nocol nocum nofreq nopercent norow;
run;

data _null;
set freq1_1;
A="T_"||substr(cohort,1,3);
call symputx ("T_"||substr(cohort,1,3),count);
run;
%put &t_asp &t_Noa &t_war;

data block1;
set freq1_1(in=a) freq1_2(in=b);
VALUE=put(count,3.);
if VALUE='.' then VALUE=' ';
length name $80;
class=1;
if a then do;
part=1;
name='No. of Subjects';
end;
if b then do;
if CNSR=0 then name='^{nbspace 5}'||'NO. of Subject with an Event (%)';
else if CNSR=1 then name='^{nbspace 5}'||'NO. of Subject without an Event (%)';
part=CNSR+2;
end;
run;

proc sort data=block1;
by class part name;
run;

data block1_;
length VALUE $10;
set block1;
by class part name;
if PERCENT ne . then VALUE=put(COUNT,3.)||'('||put(PERCENT,4.2)||'%'||')';
run;

proc transpose prefix=_ data=block1_ out=block1_transpose(drop=_Name_);
by class part name;
var VALUE;
id COHORT;
run;



proc sort data=ands.os;
by cohort;
run;
ods trace on;
ods output HomTests=pvalue(where=(test in('Log-Rank','Wilcoxon')))
Quartiles=qrts;
proc lifetest data=ands.os alpha=0.05 outsurv=outsurvl;
time AVAL*CNSR(1);
strata cohort;
run;
ods trace off;

data q_25(keep=cohort q_25 class) q_50(keep=cohort q_50 class)
q_75(keep=cohort q_75 class) q_50_ci(keep=cohort cil class);
set qrts;
class=2;
if Estimate ne . then Estimate_=put(Estimate,5.2);
else Estimate_='NA';
if Percent=25 then q_25=strip(Estimate_);
else if Percent=50 then q_50=strip(Estimate_);
else if Percent=75 then q_75=strip(Estimate_);
cil='('||strip(put(LOwerLimit,5.2))||','||strip(put(UpperLimit,5.2))||')';
if Percent=25 then output q_25;
if Percent=50 then output q_50;
if Percent=75 then output q_75;
if Percent=50 and cil ne '' then output q_50_ci;
run;

proc sort data=q_25;
by cohort;
run;
proc sort data=q_75;
by cohort;
run;
data q_25_q_75;
merge q_25 q_75;
by cohort class;
q_25_q_75=strip(q_25)||'-'||strip(q_75);
part=3;
name='25th-75th percentile';
run;

data block2;
length name $40. Value $20.;
set q_50(in=a) q_50_ci(in=b) q_25_q_75(in=c);
class=2;
if a then do;
name='^{nbspace 5}'||'Median';
part=1;
value=q_50;
end;
else if b then do;
name='^{nbspace 5}'||'(95% CI)';
part=2;
value=cil;
end;
else if c then do;
name='^{nbspace 5}'||'(25th-75th percentile)';
part=3;
value=q_25_q_75;
end;
run;
proc sort data=block2;
by class part name;
run;
proc transpose prefix=_ data=block2 out=block2_transpose(drop=_Name_);
by class part name;
var Value;
id cohort;
run;

data final;
length _Aspirin _NOAC _Warfarin $40;
set block1_transpose block2_transpose;
run;

/*report*/
ods escapechar="^";
%put &t_asp &t_Noa &t_war;
ods pdf file='/home/u63531299/taskc/t-os_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-os_heor1.rtf' style=Journal;
title1 "Overall Survival Summary";
title2 "AF Patients who are treated with Aspirin, Warfarin and NOAC";
proc report data=final out=final_ nowindows split="|";
column (class part name _NOAC _Warfarin _Aspirin );
define class/ order noprint;
define part/ order noprint;
define class/ group noprint;
define name/ display " " width=21 style (column)=[just=left cellwidth=35%];
define _NOAC/ group "NOAC | (n = &t_Noa)" style (column)=[just=c cellwidth=15%];
define _Aspirin/ group "ASPIRIN | (N = &t_asp)" style (column)=[just=c cellwidth=15%];
define _Warfarin/ group "WARFARIN | (N = &t_war)" style (column)=[just=c cellwidth=15%];
compute after class;
line ' ';
endcomp;
run;
title;
ods pdf close;
ods rtf close;

/*Summary of Stroke & Bleeding Occurrence - Binary Analysis*/
options validvarname=v7;
data strok1 (keep=patient_id STROK cohort: rename=(STROK=Resp))
bleed1(keep=patient_id Bleed cohort: rename=(Bleed=Resp));
set ands.cohort;
if strok ne . then strok=1;
else if strok eq . then strok=2;
if bleed ne . then bleed=1;
else if bleed eq . then bleed=2;
if CohortM in (2 3) then Cohort1N=2;
else if CohortN=1 then Cohort1N=1;
keep patient_id strok bleed cohort cohortn Cohort1n;
run;

proc sql noprint;
select count (distinct patient_id) into : trtX from Strok1 where cohort="NOAC";
select count (distinct patient_id) into : trtY from Strok1 where cohort="Aspirin";
select count (distinct patient_id) into : trtZ from Strok1 where cohort="Warfarin";
select strip(put(count (distinct patient_id),5.)) into : trt1 from Strok1 where Cohort1N=1;
select strip(put(count (distinct patient_id),5.)) into : trt2 from Strok1 where Cohort1N=2;
%put &trtX &trtY &trtZ &trt1 &trt2;
quit;

%let ds=Strok1;
%let label=Stroke;
%macro binary_chi(ds=Strok1,label=Stroke);
proc sort data=&ds. out=bi_resp;
by Cohort1N COHORT;
run;
ods trace on;
ods output OneWayFreqs=respfreq(rename=(frequency=count))
BinomialCLs=limit(where=(Type="Clopper-Pearson (Exact)"))
BinomialTest=test;
proc freq data=bi_resp order=formatted;
by COHORT1n;
tables resp/ fisher exact binomial(exact) nocol norow nopercent out=limitx;
run;
/*For P vale-fisher Exact*/
ods output FishersExact=fisher(where=(name1='XP2_FISH') keep=name1 cvalue1)
ChiSq=ChiSq(where=(statistic="Chi-Square") keep=statistic prob);
proc freq data=bi_resp order=formatted;
tables Cohort1N * resp/fisher exact binomial nocol norow nopercent out=limitx;
*by cohort1n;
run;
ods output close;
ods trace off;
data limit2;
set limit;
CP="("||strip(put(LowerCL*100,5.2))||", "||strip(put(UpperCL*100,5.2))||")";
avalc=" (95% CI)";
keep CP cohort1n avalc;
run;
data respfreq1;
set respfreq;
if resp=1 then do;
if cohort1n=1 then denom=&trt1;
if cohort1n=2 then denom=&trt2;
CD=count||"/"||left(denom);
percent=put((count/denom)*100,5.1);
CP=strip(CD)||" ("||strip(percent)||")";
end;

avalc="Proportion (n/N)";
if resp=2 then delete;
keep cp cohort1n avalc;
run;

data resp_1;
length CP $50 avalc $50;
set respfreq1 limit2;
run;

proc sort data=resp_1 out=resp_2;
by descending avalc;
run;
proc transpose data=resp_2 out=resp_3 (drop=_NAME_) prefix=_;
by descending avalc;
id cohort1n;
var cp;
run;
/*P Vaue*/
data chisq1;
set chisq;
avalc="Chi-Square P Value";
_l=put(Prob,6.4);
keep avalc _l;

data resp_4_&ds.;
set resp_3 (in=a) chisq1(in=b);
if a then ord=1;
else if b then ord=2;
param="&label.";
run;
%mend;

%binary_chi(ds=Strok1,label=Stroke);
%binary_chi(ds=Bleed1,label=Bleeding);

data all;
set resp_4_:;
if _1=" " then _1=_l;
run;

ods pdf file='/home/u63531299/taskc/t-bleeding_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-bleeding_heor1.rtf' style=Journal;
options center nonumber nodate;
title2 "Summary of Stroke & Bleeding Occurrence - Binary Analysis";
title3 "AF Subjects with Aspirin Warfarin or NOAC";
footnote1 "P Value is Calculated using Chi Square.";
proc report data=all nowd headline split="*" center wrap spacing=1 style(header)=[just=c];
column param avalc ord ('Cohorts' "___________________" _1 _2);
define param/"Parameter" order order=data style (column)=[just=l cellwidth=15%];
define avalc/" " style (column)=[just=l cellwidth=25%];
define ord/" " group order order=internal noprint;
define _1/"NOAC * (n=&trt1)" Display center style (column)=[just=c cellwidth=20%];
define _2/"Aspirin+Warfarin * (n=&trt2)" Display center style (column)=[just=c cellwidth=20%];

compute after ord;
line ' ';
endcomp;
compute before;
endcomp;
run;
title;
ods pdf close;
ods rtf close;

/*Drug Treatment Pattern Summary*/
data presc_1;
set ands.trt_pattern;
length presc $10. cat $10.;
if num_presc le 2 then presc='0-2';
else if num_presc >=5 then presc='5 or More';
else if num_presc =3 then presc='3';
else if num_presc =4 then presc='4';
if num_cat >=2 then cat='2 or More';
else if num_cat =0 then cat='0';
else if num_cat =1 then cat='1';
output;
cohort='All';CohortN=9;Cohort1n=9;
output;
run;

proc sql noprint;
select count(distinct patient_id) into :N1 - :N4 
from presc_1 group by cohortn
order by cohortn;
quit;
%put &N1 &N2 &N3 &N4;

proc freq data=presc_1;
tables cohort*cohortn*presc/out=freq_1(drop=percent);
tables cohort*cohortn*cat/out=freq_2(drop=percent);
title 'Prescription in Cohort';
run;

data freq_3;
set freq_1(in=a rename=(presc=cat))
freq_2(in=b);
length col1 $50;
if a then Col1="Number of Prescriptions";
else if b then Col1="Number of Different AF TReatment Category Received";
if cohortn=1 then val=put(count,5.)||" ("||put(count*100/&N1,5.2)||")";
else if cohortn=2 then val=put(count,5.)||" ("||put(count*100/&N2,5.2)||")";
else if cohortn=3 then val=put(count,5.)||" ("||put(count*100/&N3,5.2)||")";
else if cohortn=9 then val=put(count,5.)||" ("||put(count*100/&N4,5.2)||")";
run;
proc sort;
by Col1 cat;
run;

proc transpose data=freq_3 out=freq_4 prefix=_;
by Col1 cat;
id cohortn;
var val;
run;

data dummy;
length col1 $50 cat $10;
col1="Number of Prescriptions";
cat="0-2";output;
cat="3";output;
cat="4";output;
cat="5 or More";output;
col1="Number of Different AF TReatment Category Received";
cat="0";output;
cat="1";output;
cat="2 or More";output;
run;
proc sort;
by col1 cat;
run;
data freq_5;
merge dummy freq_4;
by col1 cat;
array colx (*) _:;
do i=1 to dim(colx);
if colx(i)="" then colx(i)="0 (0)";
else colx(i)=strip(colx(i));
end;
run;

/*report*/
ods pdf file='/home/u63531299/taskc/t-trt_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-trt_heor1.rtf' style=Journal;
options center nonumber nodate;
title1 "Drug Treatment Pattern Summary";
title2 "Atrial fibrillation Patients received Aspirin, Warfarin and NOAC";
footnote1 "P Value is Calculated using Chi Square.";
proc report data=freq_5 headline headskip split="|" missing wrap spacing=1 style(header)=[just=c]
style(report)=[rules=group frame=hsides];
column (col1 cat _1 _2 _3 _9);
define col1/"Parameter" order;
define cat/order "Category";
define _1/"NOAC | (N=&N1)" group style(column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define col1/" " group style(column)=[just=c cellwidth=40%] style(header)=[just=c cellwidth=40%];
define _2/"Warfarin | (N=&N2)" group style(column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define _3/"Aspirin | (N=&N3)" group style(column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];
define _9/"NOAC | (N=&N4)" group style(column)=[just=c cellwidth=10%] style(header)=[just=c cellwidth=10%];

compute before Col1;
line " ";
endcomp;
run;
title;
ods pdf close;
ods rtf close;
/*Summary of Change in CV Pharmeters from Index Date to Last available observation*/

%macro stat_calculate(Loinc=8867-4,label=Heart Rate,ord=1);
data vs3;
set ands.Vital_Sign_Analysis;
where loinc in ("&Loinc.");
run;
ods trace on;
ods output TTests=Ttest(where=(Variances="Equal"))
Statistics=Stat;
proc ttest data=vs3;
class cohort1n;
var chg;
run;
ods trace off;

data stat1;
set stat;
Meanx=put(Mean,5.2)||" ("||put(stderr,5.2)||")";
CI=put(LowerCLMean,6.3)||" ("||put(UpperCLMean,6.3)||")";
Min_Max=put(Minimum,5.2)||" ("||put(Maximum,5.2)||")";
if class in (1 2);
keep MeanX CI Min_Max Class;
run;
proc transpose data=stat1 out=stat2 prefix=_;
ID class;
Var meanx ci min_max;
run;

data Ttest1;
set Ttest;
_Name_="P_Value";
_1=put(Probt,6.4);
keep _Name_ _1;
run;

data allstat_&ord;
set stat2 ttest1;
length Col1 $30;
if _name_="Meanx" then Col1="Mean (SE)";
else if _name_="CI" then Col1="95% CI";
else if _name_="Min_Max" then Col1="Min, Max";
else if _name_="P_Value" then Col1="T Test P Value";
Param="&label.";
ParamN="&ord.";
run;
%mend;
%stat_calculate(Loinc=8867-4,label=Heart Rate,ord=1);
%stat_calculate(Loinc=8480-6,label=Systolic blood pressure,ord=2);
%stat_calculate(Loinc=8462-4,label=Diastolic blood pressure,ord=3);
data all;
set allstat_:;
run;
options center nonumber nodate;
ods pdf file='/home/u63531299/taskc/t-sbp_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-sbp_heor1.rtf' style=Journal;
options center nonumber nodate;
title1 "Summary of Change in CV Pharmeters from Index Date to Last available observation";
title2 "AF subjects with Aspirin Warfarin or NOAC";
footnote1 "P Value is Calculated using T Test.";
proc report data=All list nowd headline headskip list;
column ParamN param Col1 _1 _2;
define ParamN/noprint order;
define Col1/"Statistics" display format=$30. style (column)=[just=l cellwidth=17%] spacing=2 left;
define param/"Parameter" group format=$30. style (column)=[just=l cellwidth=25%] spacing=2 left;
define _1/"NOAC" display format=$18. style (column)=[just=c cellwidth=15%] spacing=2 left;
define _2/"Aspirin+Warfarin" display style (column)=[just=c cellwidth=15%] spacing=2 left;
compute after paramn;
line '';
endcomp;
compute before;
endcomp;
run;
title;
ods pdf close;
ods rtf close;
/*Healthcare Resource Utilizaion Summary*/
data P_1;
set ands.hru;
encounter_type=propcase(encounter_type);
output;
cohort="All";CohortN=9;Cohort1n=9;
output;
run;

proc sql noprint;
select count(distinct patient_id) into :N1 - :N4
from P_1 group by cohortn order by cohortn;
quit;
%put &N1 &N2 &N3 &N4;

proc freq data=P_1;
tables cohort*cohortn*encounter_type/out=freq_1 (drop=percent);
run;

data freq_2;
set freq_1 (in=a);
length col1 $50;
if a then COl1="Healthcare Visit: Encounter Type";
if cohortn=1 then
val=put(count,5.)||" ("||put(count*100/&N1,5.2)||")";
else if cohortn=2 then
val=put(count,5.)||" ("||put(count*100/&N2,5.2)||")";
else if cohortn=3 then
val=put(count,5.)||" ("||put(count*100/&N3,5.2)||")";
else if cohortn=9 then
val=put(count,5.)||" ("||put(count*100/&N4,5.2)||")";
run;
proc sort; by col1 encounter_type;
run;
proc transpose data=freq_2 out=freq_3 prefix=_;
by col1 encounter_type;
id cohortn;
var val;
run;

data freq_4;
set freq_3;
by col1 encounter_type;
array colx(*) _:;
do i=1 to dim(colx);
if colx(i)="" then colx(i)="0 (0)";
else colx(i)=strip(colx(i));
end;
run;

/*report*/
ods pdf file='/home/u63531299/taskc/t-hru_heor1.pdf' style=Journal;
ods rtf file='/home/u63531299/taskc/t-hru_heor1.rtf' style=Journal;
options nonumber nodate;
ods escapechar="^";
title1 "Healthcare Resource Utilizaion Summary";
title2 "Atrial fibrillation Patients received Aspirin, Warfarin and NOAC";
footnote1 "P Value is Calculated using Chi Square.";
proc report data=freq_4 headline headskip split="|" missing wrap spacing=1 style(header)=[just=c]
style(report)=[rules=group frame=hsides];
column (col1 encounter_type _1 _2 _3 _9);
define col1/"Parameter" order ;
define encounter_type/order "Encounter Visits";
define _1/"NOAC | (N=&N1)" group style(column)=[just=c cellwidth=15%] style(header)=[just=c cellwidth=10%];
define col1/" " group style(column)=[just=c cellwidth=40%] style(header)=[just=c cellwidth=40%];
define _2/"Warfarin | (N=&N2)" group style(column)=[just=c cellwidth=15%] style(header)=[just=c cellwidth=10%];
define _3/"Aspirin | (N=&N3)" group style(column)=[just=c cellwidth=15%] style(header)=[just=c cellwidth=10%];
define _9/"NOAC | (N=&N4)" group style(column)=[just=c cellwidth=20%] style(header)=[just=c cellwidth=10%];

compute before Col1;
line " ";
endcomp;
run;
title;
ods pdf close;
ods rtf close;