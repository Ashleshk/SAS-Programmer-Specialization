title1 'a';
title2 'b';
proc print data=pg1.np_summary;
run;
title2 'c';
proc print data=pg1.np_summary;
run;

title "top";
proc print data=pg1.np_summary;
run;

proc freq data=sashelp.shoes nlevels;
   tables Region / nocum;
run;