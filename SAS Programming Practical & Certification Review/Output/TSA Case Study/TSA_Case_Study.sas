/* Accessing DAta */
%let path=/home/u47489920/ECRB94/data;
libname tsa "&path";

options validvarname=v7;

proc import datafile="&path/TSAClaims2002_2017.csv"
			dbms=csv
			out=tsa.ClaimsImport
			replace;
		guessingrows=max;
run;
/* EXploring Data */
proc print data=tsa.ClaimsImport(obs=20);
run;

proc contents data=tsa.claimsimport varnum;
run;

proc freq data=tsa.claimsimport;
	tables claim_site
			disposition
			claim_type
			date_received
			incident_date / nocum nopercent;
	format incident_date date_received year4.;

run;

proc print data=tsa.claimimport;
	where date_received < incident_date;
	format date_received incident_date date9.;
run;

/* Preparation data */
/* 1. Remove duplicate rows. */
proc sort data=tsa.ClaimsImport 
		  out=tsa.Claims_NoDups noduprecs;
	by _all_;
run;

/* 2. Sort the data by ascending Incident_Date. */
proc sort data=tsa.claims_nodups;
	by Incident_Date;
run;

data tsa.claims_cleaned;
	set tsa.claims_nodups;
/* 3. Clean the Claim_Site column. */
	if Claim_Site in ('-','') then Claim_Site="Unknown";
/* 4. Clean the Disposition column. */
	if Disposition in ('-',"") then Disposition = 'Unknown';
		else if disposition = 'losed: Contractor Claim' then Disposition = 'Closed:Contractor Claim';
		else if Disposition = 'Closed: Canceled' then Disposition ='Closed:Canceled';
/* 5. Clean the Claim_Type column. */
	if Claim_Type in ('-','') then Claim_Type = "Unknown";
		else if ClaimType = 'Passenger Property Loss/Personal Injur' then Claim_Type='Passenger Property Loss';
		else if ClaimType = 'Passenger Property Loss/Personal Injury' then Claim_Type='Passenger Property Loss';
		else if ClaimType = 'Passenger Damage/Personal Injury' then Claim_Type='Passenger Damage';
/* 6. Convert all State values to uppercase and all StateName values to proper case. */
	State=upcase(state);
	StateName=propcase(StateName);
/* 7. Create a new column to indicate date issues. */
	if(Incident_Date > Date_Received or
		Date_Received = . or
		Incident_Date = . or
		year(Incident_Date)<2002 or
		year(Incident_Date)>2017 or
		year(Date_Received)<2002 or
		year(Date_Received)>2017) then Date_Issues="Needs Review";
/* 8. Add permanent labels and formats. */
	format Incident_Date Date_Received date9. Close_Amount Dollar20.2;
	label Airport_Code="Airport Code"
		  Airport_Name="Airport Name"
		  Claim_Number="Claim Number"
		  Claim_Site="Claim Site"
		  Claim_Type="Claim Type"
		  Close_Amount="Close Amount"
		  Date_Issues="Date Issues"
		  Date_Received="Date Received"
		  Incident_Date="Incident Date"
		  Item_Category="Item Category";
/* 9. Exclude County and City from the output table. */
	drop county city;
run;

proc freq data=tsa.claims_cleaned order=freq;
	tables Claim_Site
			Disposition
			Claim_Type
			Date_Issues / nopercent nocum;
run;

%let statename=North Carolina;
%let outpath=/home/u47489920/ECRB94/output;
ods pdf file="&outpath/ClaimsReport.pdf" style=meadow pdftoc=1;
ods noproctitle;
/* Analyzing the Data */
/* 1. How many date issues are in the overall data? */
ods proclabel "Overall Date Issues";
title "Overall Date Issues in the Data";
proc freq data=tsa.claims_cleaned;
	table Date_Issues /missing nocum nopercent;
run;
title;
/* 2. How many claims per year of Incident_Date are in the overall data? Be sure to include a plot. */
ods graphics on;
ods proclabel "Overall Claims by Year";
title "Overall Claims by year";
proc freq data=tsa.claims_cleaned;
	table Incident_Date /nocum nopercent plots=freqplot;
	format Incident_Date year4.;
	where Date_Issues is null;
run;
title;
/* SPECIAL STATE ANALYSIS */
/* 3. Lastly, a user should be able to dynamically input a specific state value and answer the following: */
/* a. What are the frequency values for Claim_Type for the selected state? */
/* b. What are the frequency values for Claim_Site for the selected state? */
/* c. What are the frequency values for Disposition for the selected state? */
ods proclabel "&statename Claims Overview";
title "&statename Claim Types, Claim Sites and Disposition";
proc freq data=tsa.claims_cleaned order=freq;
	table Claim_Type Claim_Site Disposition /nocum nopercent;
	where StateName="&statename" and Date_Issues is null;
run;
title;

/* d. What is the mean, minimum, maximum, and sum of Close_Amount for the selected state? */
/* The statistics should be rounded to the nearest integer. */
ods proclabel "&statename Close Amount Statistics";
title "Close_amount Statistics for &statename";
proc means data=tsa.claims_cleaned mean min max sum maxdec=0;
	var Close_Amount;
	where StateName="&statename" and Date_Issues is null;
run;
title;

ods pdf close;
/* Exporting Reports */











