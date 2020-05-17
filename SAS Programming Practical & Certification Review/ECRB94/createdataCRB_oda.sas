/*************************************************************
 Note: This program will not run properly on z/OS.
       Only Windows, Linux and UNIX are supported.
       Values for PATH are CASE SENSITIVE.
*************************************************************/
%let path=/home/&sysuserid/ECRB94;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 WARNING: DO NOT ALTER CODE BELOW THIS LINE IN ANY WAY
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/* Make sure path consistently uses forward slashes */
%let course=ecrb94;
%let path=%qsysfunc(translate(%superq(path),/,\));
%let original_path=%superq(path);

/*options nomprint nosymbolgen nonotes nosource dlcreatedir;*/
options mprint symbolgen notes source;

%macro unpack(unzip /* Full path pointing to where to create the ECRB94 data */
             ,zipfilename /* ZIP File name (used to download with PROC HTTP) */
             ,coursecode /* Represents the top level folder of the ZIP file; can be used for conditional logic */);

%local rc fid fileref fnum memname big_zip big_zip_found data_zip data_zip_found url;
%global cre8data_success path;
%let cre8data_success=0;
%let url=%str(http://dl.liveweb.sas.com/eldata/crb94_oda.zip);


/* Is the path specified valid? */
%let fileref=unzip;  
%let rc=%sysfunc(filename(fileref,%superq(unzip)));
%let path_found=%sysfunc(fileref(unzip));
%if &path_found ne 0 %then %do;
   %put %sysfunc(sysmsg());
   %put ERROR: ************************************************************;
   %put ERROR- Path specified for data files (%superq(unzip)) is not valid.;
   %put ERROR- Remember: PATH values in UNIX and LINUX are case sensitive. ;
   %put ERROR- ************************************************************;
   %let rc=%sysfunc(filename(fileref));
   %return;
%end;

/* Get just the filename of the zipfile, not the .ZIP extension */
%if %qscan(%qupcase(%superq(zipfilename)),2,.) = %str(ZIP) %then %do;
   %let zipfilename = %qscan(%superq(zipfilename),1,.) ;
%end;

/* Test for the presence of the main ZIP file in the path */
%let fileref=bigzip;
%let rc=%sysfunc(filename(fileref,%superq(unzip)/%superq(zipfilename).zip,zip));
%let big_zip_found=%sysfunc(fileref(bigzip));
%if &big_zip_found ne 0 %then %do;
   %put NOTE: %superq(zipfilename).zip not found in %superq(unzip).;
   %put NOTE- Attempting to download the ZIP file from the internet.;
   filename BigZip "%superq(unzip)/%superq(zipfilename).zip";
   proc http 
      url="%superq(url)"
      out=BigZip method="get";
;

run;

   %let big_zip_found=%sysfunc(fileref(bigzip));
   %if &big_zip_found ne 0 %then %do;
      %put ERROR: *************************************************************;
      %put ERROR-   Attempt to download %superq(zipfilename).zip unsuccessful.;
      %put ERROR- *************************************************************;
      filename BigZip;
      %return;
   %end;
%end;

options dlcreatedir;
libname xx "%superq(path)";
libname xx clear;

/* Read the "members" (files) from the ZIP file */
/* Create the data folder structure and get a list of files in macro variables */
filename BigZip zip "%superq(unzip)/%superq(zipfilename).zip";
data _null_;
   length memname pathname $500;
   fid=dopen("bigzip");
   if fid=0 then stop;
   memcount=dnum(fid);
   do i=1 to memcount;
      memname=dread(fid,i);
      /* Create and empty folder for each folder in the ZIP file */
      /* check for trailing / in folder name */
      isFolder = (first(reverse(trim(memname)))='/');
/*         if isfolder then put memname= isfolder=;*/
      if isfolder then do;
         pathname=cats("&path/",substr(memname,1,length(memname)-1));
         put "NOTE: Creating path " pathname;
         rc1=libname('xx',pathname);
         rc2=libname('xx');
      end;
      else do;
         filecount+1;
         call symputx(cats('out',filecount),memname,'L');
      end;
   end;
   rc=dclose(fid);
   call symputx('filecount',filecount,'L');
run;

%do i=1 %to &filecount;
   filename out "%superq(unzip)/%superq(out&i)";
    data _null_;
      infile bigzip(%superq(out&i))
      lrecl=256 recfm=F length=length eof=eof unbuf;
      file out  lrecl=256 recfm=N;
      input;
      put _infile_ $varying256. length;
      return;
    eof:
      stop;
   run;
%end;

filename bigzip;
filename out;
filename unzip;

%let setup=%superq(unzip)/setup.sas;
%let cre8data_ready=%sysfunc(fileexist(%superq(setup)));

%if not &cre8data_ready %then %do;
      %put;
      %put ERROR: ********************************************************************;
      %put ERROR- After unzipping %superq(zipfilename).zip, setup.sas program not found ;
      %put ERROR- in folder %superq(unzip).;
      %put ERROR- Download and unzip %superq(zipfilename)_data.zip manually, then;
      %put ERROR- run cre8data.sas again.;
      %put ERROR- ********************************************************************;
      %put;
%end;

%let path=%superq(unzip)/data;

%include "%superq(setup)";

%mend unpack;

%unpack(%superq(path),ecrb94.zip,ecrb94)

/* added to set &path for elearning */
%let path=/home/&sysuserid/ECRB94/data;

options mprint notes source;
