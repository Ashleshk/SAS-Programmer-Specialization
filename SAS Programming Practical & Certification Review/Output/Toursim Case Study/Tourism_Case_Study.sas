/* Create the Cleaned_Tourism Table */
/* Part 1 */
/* 1. If necessary, redefine the cr library. Read the cr.tourism table and create the cr.cleaned_tourism table. */
/* 2. Remove the columns _1995 through _2013. */
/* 3. Create the Country_Name and Tourism_Type columns from values in the Country column. Valid values for Tourism_Type are Inbound tourism and Outbound tourism. Remove rows that contain this labeling information and no other data. */

/* Part 2 */
/* 4. In the Series column, convert values to uppercase and convert ".." to missing a character value. */
/* 5. Determine the conversion type (Mn or Thousands) that will be used to calculate values for the new Y2014 column. Hint: You might want to create a new column with this information. */
/* 6. In the _2014 column, change the data not available (values of "..") to a single period. */

/* Part 3 */
/* 7. Create the Y2014 column by explicitly converting character values in _2014 to numeric and multiplying by the conversion type (millions or thousands) that is found in the Country column or new column, if you created one. */
/* 8. Permanently format Y2014 with the COMMA format. */
/* 9. nclude only Country_Name, Tourism_Type, Category, Series, and Y2014 in the output table. */


data cr.cleaned_tourism;
	length Country_Name $300 Tourism_Type $20;
	retain Country_Name "" Tourism_Type "";
	set cr.Tourism(drop=_1995-_2013);
	if A ne . then Country_Name=Country;
	if lowcase(Country)="inbound tourism" then Tourism_Type ="Inbound tourism";
		else if lowcase(Country)="outbound tourism" then Tourism_Type="Outbound tourism";
	if Country_Name ne Country and Country ne Tourism_Type;
	series=upcase(series);
	if series=".." then Series="";
	ConversionType=scan(country,-1," ");
	if _2014=".." then _2014=".";
	if ConversionType ="Mn" then do;
		if _2014 ne "." then Y2014 = input(_2014,16.)*1000000;
			else Y2014=.;
		Category=cat(scan(country,1,'-','r'),' -US$');
	end;
	else if ConversionType ="Thousands" then do;
		if _2014 ne "." then Y2014 = input(_2014,16.)*1000;
			else Y2014=.;
		Category=scan(country,1,'-','r');
	end;
	format y2014 comma25.;
	drop A ConversionType Country _2014;
run;

proc freq data=cr.cleaned_tourism;
	tables Category Tourism_Type Series;
run;

proc means data=cr.cleaned_tourism min max n maxdec=0;
	var Y2014;
run;

/* Create the Final_Tourism Table */
/* 1. Create a format for the Continent column that labels continent IDs with the corresponding continent names: */
proc format;
	value contIDs
		1 = "North America"
		2 = "South America"
		3 = "Europe"
		4 = "Africa"
		5 = "Asia"
		6 = "Oceania"
		7 = "Antarctica";
run;
/* 2. Merge the cleaned_tourism table with a sorted version of country_info to create the final_tourism table. Include only matches in the output table. Use the new format to format Continent. */

proc sort data=cr.country_info(rename=(Country=Country_Name))
			out=country_sorted;
		by country_name;
run;

/* Create the NoCountryFound Table */

data cr.final_tourism 
	NoCountryFound(keep=Country_Name);
	merge cr.cleaned_tourism(in=t) Country_Sorted(in=c);
	by country_name;
	if t=1 and c=1 then output cr.Final_Tourism;
	if (t=1 and c=0) and first.country_name=1 then output NoCountryFound;
	format continent contIDs.;
run;

proc freq data=cr.final_tourism nlevels;
	tables category series Tourism_Type Continent /nocum nopercent;
run;

/* QUIZ */
proc means data=cr.final_tourism mean min max maxdec=0;	
	var y2014;
	class Continent;
	where Category="Arrivals";
run;

proc means data=cr.final_tourism mean maxdec=0;	
	var y2014;
	where lowcase(Category) contains "tourism expenditure in other countries";
run;	




























































