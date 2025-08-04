 /**************************************************************************************
 PROJECT    : Example Code for Portfolio
 PROGRAM    : MEPS_2017_2018
 PROGRAMMER : Emily Hernandez
 PURPOSE    : Create analytic file from input datasets and conduct descriptive analyses
 				on health insurance coverage by selected characteristics using the 
                Medical Expenditure Panel Survey, 2017 and 2018 data

 INPUTS     : MEPS 2017 and 2018 conmsolidated files (h201.xlsx and h209.xlsx)
 OUTPUTS    : MEPS_2017_2018.sas7bdat

 CREATED    : 03/11/2025
 UPDATED    : 03/11/2025

 NOTES      : Coding performed and run in SAS studio
 
 **************************************************************************************/


/*===========================================
    SYSTEM SETTINGS 
===========================================*/

%let obs_ = max;    *** USER DEFINED VALUE - CHANGE FOR TESTING VS PRODUCTION ;

options
    ls = 250 
    nocenter
    minoperator 
    mprint
    mlogic
    obs = &obs_
    symbolgen 
    validvarname = v7;


/*===========================================
    DIRECTORIES
===========================================*/

*--- for sas studio env, all data, logs, programs in same directory;
%let basedir = /home/u61925695/sasuser.v94;
%let progdir = &basedir.;
%let indir   = &basedir.;
%let datadir = &basedir.;
%let outdir  = &basedir.;
%let logdir  = &basedir.;

libname basedir "&basedir.";
libname prog    "&progdir.";
libname in      "&indir.";
libname data    "&datadir.";
libname out     "&outdir.";
libname log     "&logdir."; 


/*===========================================
    MACROS 
===========================================*/

%let datestamp  = %sysfunc(date(), yymmddn8.); *----- SETS DATESTAMP MACRO TO VALUE OF YYYYMMDD;
%let start_time = %sysfunc(datetime());        *----- SETS START FOR TIMER;

%let progname =  MEPS_2017_2018;



/*===========================================
    OPEN LOG/LST FILES 
===========================================*/

proc printto new
    log   = "&logdir./&progname._&datestamp..log"
    print = "&logdir./&progname._&datestamp..lst" 
    ;
run;


title "Program for &progname. Data Processing and Summary Statistics";

/*===========================================
    FORMATS
===========================================*/

proc format;

	value yn_ft																								
		1 = 'Yes'																							
		2 = 'No';																								
																								
	value region_ft																								
		1 = 'Northeast'																							
		2 = 'Midwest'																							
		3 = 'South'																							
		4 = 'West';																							
																								
	value hinsrc_ft																								
		1 = 'Medicare'																							
		2 = 'Medicaid'																							
		3 = 'ESI'																							
		4 = 'Private Non-ESI'																							
		5 = 'Uninsured';																							
																							
																							
	value hinsrc2_ft																								
		1 = 'Public'																							
		2 = 'Private'																							
		3 = 'Uninsured';																							
																								
	value fplcat_ft																								
		1 = '<100% fpl'																							
		2 = '100-149% fpl'																							
		3 = '150-199% fpl'																							
		4 = '200-249% fpl'																							
		5 = '250-399% fpl'																							
		6 = '>400% fpl';																							
																							
	value hlth_ft																								
		1 = 'Excellent'																							
		2 = 'Very Good'																							
		3 = 'Good'																							
		4 = 'Fair'																							
		5 = 'Poor';																							
																							
	value chrdx_ft																								
		1 = 'high blood pressure'																							
		2 = 'coronary heart disease'																							
		3 = 'stroke'																							
		4 = 'emphysema'																							
		5 = 'chronic bronchitis'																							
		6 = 'high cholesterol'																							
		7 = 'cancer'																							
		8 = 'diabetes'																							
		9 = 'arthritis'																							
		10 = 'asthma';																							
																								
	value racethx_ft																								
		1 = 'Hispanic'																							
		2 = 'Non-Hispanic White'																							
		3 = 'Non-Hispanic Black'																							
		4 = 'Non-Hispanic Asian'																							
		5 = 'Non-Hispanic Other Race or Multiracial';																							
																								
	value agecat2_ft																								
		1 = '<6 years-old'																							
		2 = '6-17 years-old'																							
		3 = '18-24 years-old'																							
		4 = '25-34 years-old'																							
		5 = '35-44 years-old'																							
		6 = '45-54 years-old'																							
		7 = '55-64 years-old'																							
		8 = '65+ years-old';																							
																							
	value agecat1_ft																								
		1 = '<18 years-old'																							
		2 = '18-64 years-old'																							
		3 = '65+ years-old';																							
																							
	value sex_ft																								
		1 = 'Male'																							
		2 = 'Female';																							

run;


/*===========================================
    IMPORT FILES 
===========================================*/

proc import datafile = "&indir./h201.xlsx"
    out = out.MEPS_2017
    dbms = xlsx replace ;  *-- CHECK LOG FOR ERRORS OR WARNINGS;
    getnames = yes;
run;

proc import datafile = "&indir./h209.xlsx"
    out = out.MEPS_2018
    dbms = xlsx replace ;  *-- CHECK LOG FOR ERRORS OR WARNINGS;
    getnames = yes;
run;



/*===========================================
    DATA PROCESSING
===========================================*/

%macro recode(year);

	/*- extract variable names ending with year (17, 18) -*/
	proc sql; 
		select cats(name, '=', substr(name, 1, length(name)-2))  /*- e.g. prints faminc18=faminc -*/
		into :rename_vars_yr separated by ' ' 
		from dictionary.columns
		where libname = "OUT"
			and memname = "MEPS_20&year."
			and name like 
				%if &year. = 18 %then %do;
					"%18";
				%end; 
				%if &year. = 17 %then %do;
					"%17";
				%end;
	quit;
	
	
		data out.MEPS_20&year._rename ;
		set  out.MEPS_20&year. ;
		
			/*- apply rename command to identified variables -*/
			rename &rename_vars_yr. ;
			
			/*- rename additional variables needed for analysis -*/
			rename  age&year.x 		= age																						
					marry&year.x 	= marry																				
					ttlp&year.x 	= ttlp																						
					tricr&year.x 	= tricr																						
					mcaid&year.x 	= mcaid																						
					mcare&year.x 	= mcare																					
					ins&year.x		= ins																				
					perwt&year.f 	= perwt				
					;
					
			/*- recode numeric values <0 to be missing -*/
			array rcnum&year. _numeric_;																								
				do over rcnum&year.;																							
					if rcnum&year. <0 then rcnum&year. =.;																						
			end;
			
			/*- recode 2017 "barriers to care" variables to match 2018 version -*/
			%if &year. = 17 %then %do;
			
				if mdunrs42 = 1 then afrdca42 = 1;																							
					else afrdca42 = 2;	
					
				if mddlrs42 = 1 then dlayca42 = 1;																							
				 	else dlayca42 = 2;	
				 	
				if dnunrs42 = 1 then afrddn42 = 1;																							
					else afrddn42 = 2;	
					
				if dndlrs42 = 1 then dlaydn42 = 1;																							
					else dlaydn42 = 2;	
					
				if pmunrs42 = 1 then afrdpm42 = 1;																							
					else afrdpm42 = 2;	
					
				if pmdlrs42 = 1 then dlaypm42 = 1;																							
					else dlaypm42 = 2;	
				
			%end;
					
		run;
		

%mend;

	%recode(year = 17);
	%recode(year = 18);

	/*- QA checks ---------------------------------------------*/
	title3 "Check 2017 recoding" ;
	proc freq data = out.meps_2017_rename;
	tables afrdca42  dlayca42  afrddn42  dlaydn42  afrdpm42  dlaypm42 / list missing;
	run;
	
	title3 "Compare with 2018 coding" ;
	proc freq data = out.meps_2018_rename;
	tables afrdca42  dlayca42  afrddn42  dlaydn42  afrdpm42  dlaypm42 / list missing;
	run;
	
	title3 "Check numeric recoding" ;
	proc freq data = out.meps_2018_rename;;
	tables famsze / list missing;
	run;
	
	
	
/*- stack files to create combined dataset -----------------------------------*/
data out.MEPS_2017_2018;
set out.meps_2017_rename
	out.meps_2018_rename ;
	
	/*- recode vars -*/
	if 0 <= age < 18 then agecat1 = 1; 																								
		else if 18 <= age < 65 then agecat1 = 2;																							
		else if age >= 65 then agecat1 = 3;																							
																									
	if 0 <= age < 6 then agecat2 = 1; 																								
		else if 6 <= age < 18 then agecat2 = 2; 																							
		else if 18 <= age < 25 then agecat2 = 3; 																							
		else if 25 <= age < 35 then agecat2 = 4; 																							
		else if 35 <= age < 45 then agecat2 = 5; 																							
		else if 45 <= age < 55 then agecat2 = 6; 																							
		else if 55 <= age < 65 then agecat2 = 7; 																							
		else if age >= 65 then agecat2 = 8;																							
																									
	/*- health insurance recode using hierarchy																								
		originally included VA, but 2017 doesn't have this var, so will exclude -*/																							
	if mcare = 1 then hinsrc = 1; *---------------------------Medicare;																									
		else if mcaid = 1 then hinsrc = 2; *------------------Medicaid;																							
		else if (prieu = 1 or tricr = 1) then hinsrc = 3; *---Employer sponsored insurance, incl tricare; 																							
		else if (prtsx = 1 or pring = 1) then hinsrc = 4; *---Private non-esi;																							
		else if ins = 2 then hinsrc = 5; *--------------------Uninsured;																							
		else hinsrc = .;																							
																									
	if hinsrc in (1,2) then hinsrc2 = 1; *-----------public;																								
		else if hinsrc in (3,4) then hinsrc2 = 2; *--private;																							
		else if hinsrc = 5 then hinsrc2 = 3; *-------uninsured;																							
		else hinsrc2 = .;																							
																									
	if hinsrc = 5 then ins2 = 2; *--uninsured;																								
		else ins2 = 1; *------------insured;																							
																									
	/*- FPL brackets - */																								
	if 0 <= povlev <100 then fplcat = 1;																								
		else if 100 <= povlev <150 then fplcat = 2;																							
		else if 150 <= povlev <200 then fplcat = 3;																							
		else if 200 <= povlev <250 then fplcat = 4;																							
		else if 250 <= povlev <400 then fplcat = 5;																							
		else if povlev >=400 then fplcat = 6;																							
																									
	/*- out of pocket (oop) exposure relative to family income	-*/																							
	if faminc >0 then oop = (totslf/faminc);																								
																									
	/*- chronic condition diagnoses - */																								
	if hibpdx = 1 then chronicdx = 1;																								
		else if chddx = 1 then chronicdx = 2;																							
		else if strkdx = 1 then chronicdx = 3; 																							
		else if emphdx = 1 then chronicdx = 4; 																							
		else if chbron31 = 1 then chronicdx = 5; 																							
		else if choldx = 1 then chronicdx = 6; 																							
		else if cancerdx = 1 then chronicdx = 7; 																							
		else if diabdx = 1 then chronicdx = 8; 																							
		else if arthdx = 1 then chronicdx = 9; 																							
		else if asthdx = 1 then chronicdx = 10;																							
		else chronicdx =.;																							
																									
	/*- person-level weight var needs be adjusted to account for combined years -*/																								
	if perwt >0 then perwt1718 = (perwt/2);	
	
	/*- add labels to variables -*/
	label 																								
		hinsrc2 	= 'health insurance status (recoded)'																							
		rthlth53 	= 'health status'																							
		mnhlth53 	= 'mental health status'																							
		haveus42 	= 'has a usual source of care' 																							
		dlayca42 	= 'delay in medical care due to cost' 																							
		afrdca42 	= 'could not afford medical care' 																							
		dlaydn42 	= 'delay in dental care due to cost' 																							
		afrddn42 	= 'could not afford dental care' 																							
		dlaypm42 	= 'delay in Rx due to cost' 																							
		afrdpm42 	= 'could not afford Rx'																							
		probpy42 	= 'family having problems paying medical bills' 																							
		crfmpy42 	= 'family medical bills being paid over time' 																							
		pyunbl42 	= 'unable to pay family medical bills'																							
		oop 		= 'out of pocket spending relative to family income'																							
		totslf 		= 'total health expenditures paid by self/family'																							
		chronicdx 	= 'chronic disease diagnosis'																							
		offer53x 	= 'has offer of health insurance' 																							
		ofremp53 	= 'employer offers health insurance'	
		;
run;


/*- QA checks ---------------------------------------------*/
	title3 "QA check : MEPS_2017_2018 recoded characteristic variables";
	proc freq data=out.meps_2017_2018;
	tables agecat1 agecat2 hinsrc hinsrc2 ins2 fplcat chronicdx/ list missing;
	run;



/*===========================================
    SUMMARY STATISTICS - OUTPUT TO EXCEL
===========================================*/

ods excel file = "&basedir./&progname._summary_stats_&datestamp..xlsx"
			options(sheet_interval = "proc");

title2 "&progname. Summary Statistics Output";

	title3 "Health status and medical conditions by insurance coverage, stratified by region";
	proc surveyfreq data = out.meps_2017_2018;
	tables region * rthlth53 * hinsrc2																								
			region * mnhlth53 * hinsrc2																						
			region * chronicdx * hinsrc2 
			;
	stratum varstr;																								
	cluster varpsu;																								
	weight perwt1718;
	format region region_ft.																					
			rthlth53 hlth_ft.																						
			mnhlth53 hlth_ft.																						
			chronicdx chrdx_ft.																						
			hinsrc2 hinsrc2_ft.
			;
	run;
	
	
	
	title3 "Access/barriers to healthcare by insurance coverage, stratified by region";
	proc surveyfreq data = out.meps_2017_2018;
	tables region * haveus42 * hinsrc2																								
			region * dlayca42 * hinsrc2																						
			region * afrdca42 * hinsrc2																						
			region * dlaydn42 * hinsrc2																						
			region * afrddn42 * hinsrc2																						
			region * dlaypm42 * hinsrc2																						
			region * afrdpm42 * hinsrc2	
			;
	stratum varstr;																								
	cluster varpsu;																								
	weight perwt1718;
	format region region_ft.																					
			haveus42 yn_ft.																						
			dlayca42 yn_ft.																						
			afrdca42 yn_ft.																						
			dlaydn42 yn_ft.																						
			afrddn42 yn_ft.																						
			dlaypm42 yn_ft.																						
			afrdpm42 yn_ft.																						
			hinsrc2 hinsrc2_ft.
			;
	run;


	title3 "Problems paying bills by insurance coverage, stratified by region";
	proc surveyfreq data = out.meps_2017_2018;
	tables region * probpy42 * hinsrc2																								
			region * crfmpy42 * hinsrc2																						
			region * pyunbl42 * hinsrc2	
			;
	stratum varstr;																								
	cluster varpsu;																								
	weight perwt1718;
	format region region_ft.																						
			probpy42 yn_ft.																						
			crfmpy42 yn_ft.																						
			pyunbl42 yn_ft.																						
			hinsrc2 hinsrc2_ft.
			;
	run;



	title3 "Out of pocket exposure by insurance coverage, stratified by region";
	proc surveymeans data = out.meps_2017_2018 mean min max std;
	var oop;																								
	domain region * hinsrc2 * fplcat																								
			;
	stratum varstr;																								
	cluster varpsu;																								
	weight perwt1718;
	format region region_ft.																					
			hinsrc2 hinsrc2_ft.																						
			fplcat fplcat_ft.
			;
	run;
	
ods excel close;
	
/*===========================================
    CLOSE LOG/LST FILES 
===========================================*/
proc printto;
run;
