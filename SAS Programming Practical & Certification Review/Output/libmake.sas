**************************************************;
*   SAS Programming Process                      *;
**************************************************;
*   This program is an example of code that you  *;
*   learn in the class to analyze international  *;
*   storm data. The program follows the SAS      *;
*   programming process:                         *;
*    1) Access data                              *;
*    2) Explore data                             *;
*    3) Prepare data                             *;
*    4) Analyze and report on data               *;
*    5) Export results                           *;
**************************************************;

***************;
* Section 1:  *;
* Access Data *;
***************;

options validvarname=v7;
ods graphics on;

*Path is assigned in the cre8data.sas program;
%let path=/home/u47489920/EPG194/;
%let outpath=/home/u47489920/EPG194/output;

libname pg1 base "/home/u47489920/EPG194/data";

proc import datafile="/home/u47489920/EPG194/data/storm.xlsx" 
			dbms=xlsx out=storm_damage replace;
	sheet="Storm_Damage";
run;

****************;
* Section 2:   *;
* Explore Data *;
****************;

title "Explore Basin and Status Codes";
proc freq data=pg1.storm_summary;
	tables basin type;
run;

title "Summary Statistics for Maximum Wind(MPH) and Minimum Pressure";
proc means data=pg1.storm_summary;
	var MaxWindMPH MinPressure;
run;

title "First 5 Rows from Imported Storm Damage";
proc print data=storm_damage(obs=5);
run;

*******************;
* Section 3:      *;
* Prepare Data    *;
*******************;

data storm_summary2;
	set pg1.storm_summary pg1.storm_2017(drop=location);
	length OceanCode $ 7 BasinName $ 14;
	drop oceancode;
	Basin=upcase(basin);
	OceanCode=substr(basin,2,1);
	key=cats(season,name);
	StormLength=enddate-startdate;

	if oceancode="A" then Ocean="Atlanic";
	else if oceancode="P" then Ocean="Pacific";
	else if oceancode="I" then Ocean="Indian";

	if Basin="NA" then BasinName="North Atlantic";
	else if Basin="SA" then BasinName="South Atlantic";
	else if Basin="WP" then BasinName="West Pacific";
	else if Basin="EP" then BasinName="East Pacific";
	else if Basin="SP" then BasinName="South Pacific";
	else if Basin="NI" then BasinName="North Indian";
	else if Basin="SI" then BasinName="South Indian";
run;

data storm_damage2;
	set storm_damage;
	Name=upcase(scan(Event,-1));
	Season=Year(date);
	key=cats(season,name);
	drop Event Date;
	format Cost dollar16.;
run;

proc sql;
create table damage_detail as
select d.name, d.season, basinname, maxwindmph, minpressure, stormlength, cost, deaths
    from storm_damage2 as D, storm_summary2 as S 
    where d.key=s.key order by cost desc;
quit;

*******************************;
* Section 4:                  *;
* Analyze and Report on Data  *;
* Export Results              *;
*******************************;
%let Year=2016;
%let basin=North Atlantic;
ods noproctitle;
ods excel file="&path/output/storm_report&year..xlsx" 
          options(sheet_interval="proc" 
          sheet_name="&Year Storms by Basin" 
          embedded_titles="yes");

title1 "Number of Storms by Type and Basin";
title2 "&year Season";
proc freq data=storm_summary2 order=freq;
    tables basinname / nopercent nocum plots=freqplot;
	tables basinname*type / norow nocol crosslist ;
	where season=&year;
run; 

ods excel options(sheet_name="&year Wind Statistics");
title1 "Wind Statistics by Storm";
title2 "Year &year";
proc means data=pg1.storm_detail mean min max maxdec=0 nonobs;
	class name;
	var wind;
	where season=&year;
	output out=hur_stats mean=AvgWind min=MinWind max=MaxWind;
run;

data map;
	set storm_summary2;
	length maplabel $ 20;
	where season=&year and basinname="&basin";
	if maxwindmph<100 then MapLabel=" ";
	else maplabel=cats(name,"-",maxwindmph,"mph");
	keep lat lon maplabel maxwindmph;
run;

title1 "Tropical Storms in &year Season";
title2 "&basin Basin";
footnote1 "Storms with MaxWind>100mph are labeled";

ods excel options(sheet_name="&year &Basin Basin");
proc sgmap plotdata=map;
    *openstreetmap;
    esrimap url='http://services.arcgisonline.com/arcgis/rest/services/World_Physical_Map';
    bubble x=lon y=lat size=maxwindmph / 
		   datalabel=maplabel datalabelattrs=(color=red size=8);
run;
ods excel close;
ods proctitle;
title;footnote;
