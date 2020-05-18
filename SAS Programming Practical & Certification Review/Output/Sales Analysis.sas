/* Accessing  data */
%let path=~/ECRB94/data;

options validvarname=v7;
libname ctryxl xlsx "&path/country_lookup.xlsx";

libname cr "&path/output";
proc import datafile="&path/orders.csv" out=cr.orders dbms=csv replace;
run;

proc contents data=cr.orders;
run;

proc contents data=ctryxl._all_ nods;
run;

/* Exploring Data */
/* Validate Country LookUp Excel Table */
proc print data=ctryxl.countries;
run;

proc freq data=ctryxl.countries order=freq;
	tables Country_key Country_Name;
run;

proc sort data=ctryxl.countries out=country_clean nodupkey dupout=dups;
  	by country_key;
run;

/* Validate Imported orders Table */
proc print data=cr.orders;
	where order_date>Delivery_date;
	var Order_ID Order_Date Delivery_Date;
run;

proc freq data=cr.orders;
	tables Order_type Customer_Country Customer_continent;
run;

proc univariate data=cr.orders;
	var Quantity Retail_price Cost_price;
run;

/* Preparing the Data */
data Profit;
	set cr.orders;
	length Order_Source $8;
	where Delivery_Date>=Order_Date;
	Customer_Country=upcase(Customer_Country);
	if Quantity <0 then Quantity=.;
	Profit=(Retail_Price-Cost_Price)*Quantity;
	format Profit dollar12.2;
	ShipDays=Delivery_Date-Order_Date;
	Age_Range=substr(Customer_Age_Group,1,5);
	if Order_Type=1 then Order_Source="Retail";
	else if Order_Type=2 then Order_Source="Phone";
	else if Order_Type=3 then Order_Source="Internet";
	else Order_Source="Unknown";
	drop Retail_Price Cost_Price Customer_Age_Group Order_Type;
run;


proc sql;
	create table profit_country as
	select profit.*,Country_Name
	from profit inner join country_clean
	on profit.Customer_Country=country_clean.Country_key
	order by Order_date desc;
quit;

/* Order Frequency Analysis */
ods noproctitle;
title "Number of Orders by Month";
title2 "and Customer Continent/Order Source";
proc freq data=profit_country order=freq;
	tables Order_Date / nocum;
	format Order_date monname.;
	tables Customer_continent*Order_Source /norow nocol;
run;


%let os=Phone;
proc sort data=profit_country out=profit_country_sort;
	by order_Source;
run;
title "Days to ship by Country";
proc means data=profit_country_sort min max mean maxdec=0;
	var ShipDays;
	class Country_Name;
	where Shipdays>0 and Order_Source="&os";
	by Order_Source;
run;

proc means data=profit_country noprint;
 	var Profit;
 	class Age_Range;
 	output out=profit_summary median=MedProfit sum=TotalProfit;
 	ways 1;
run;

title "Profit by Customer Age_range";
proc print data=profit_summary noobs;
	var Age_range TotalProfit MedProfit;
	label Age_Range="Age Range"
			TotalProfit="Total Profit"
			medProfit="Median Profit Per Order";
	format TotalProfit MedProfit dollar10.;
run;


/* Exporting Data */
proc export data=profit_Country outFile="&path/output/orders_update.xlsx" dbms=xlxs replace;
run;

libname outxl xlsx "&path/output/orders_update.xlsx";

data outxl.Orders_Update;
	set profit_country;
run;

data outxl.Country_Lookup;
	set country_clean;
run;

proc means data=profit noprint;
	var profit;
	class Age_Range;
	ways 1;
	output out=outxl.profit_summary;
run;

libname outxl clear;

















