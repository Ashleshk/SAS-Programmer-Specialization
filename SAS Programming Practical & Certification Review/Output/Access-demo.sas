proc contents data=cr._all_ nods;
run;

/* programming Exercise -2 */
%let path=~/ECRB94/data;

proc import datafile="&path/payroll.csv" out=payroll dbms=csv replace;
	guessingrows=max;
run;

proc contents data=payroll;
run;

/* programming exercise -3 */
options validvarname=v7;
libname xl xlsx "&path/employee.xlsx";
proc contents data=xl._all_;
run;