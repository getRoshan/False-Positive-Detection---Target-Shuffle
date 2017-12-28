DM 'output;clear;log;clear;';				
LIBNAME black "C:\Users\Koffi\Desktop\LSU MSA\MKT7716\SAS Component";
%LET Number_Shuffle=100;

proc transpose data = black.hbat_200 out = dataout;
    var x19;
run;
/*proc print data=dataout ;*/
/*run;*/
data black.shuff;
   set dataout;
   ex=0;
   drop i j ex _NAME_ _LABEL_ ran;
   array sh{*} col1-col200;
   do i = 1 to &Number_Shuffle;
       do j = 200 to 2 by -1;
	      ran = int(rand("uniform")* j + 1);
		  do while (ran=j);
		      ran = int(rand("uniform")* j + 1);
		  end;
           ex=sh{j};
           sh{j}=sh{ran};
		  sh{ran}=ex;
		end;
		output;
	end;
run;
/*proc print data=black.shuff (obs=5);*/
/*run;*/

proc transpose data = black.shuff  out = black.shuff_tp;
run;

/*proc print data=black.shuff_tp(obs=5);*/
/*run;*/

/*data black.test;
    merge black.shuff_tp black.hbat_1000;
run;*/

/*Creating stacked dataSET*/

data final dummy;
  set black.hbat_200;
run;

%macro ds;
   %do i=1 %to &Number_Shuffle-1;
	 proc append base=final  data=dummy;
   %end;
run;
%mend;
%ds;
run;
/*Creating stacked shuffled Y and Imputation Variable*/
%macro try;
   data y1(keep=_Imputation_ y);
      set black.shuff_tp(rename =(COL1=Y));
	 _Imputation_=1;
	run;
   %do i=2 %to &Number_Shuffle;   
   data y&i(keep=_Imputation_ y);
      set black.shuff_tp(rename =(COL&i=Y));
	 _Imputation_=&i;
	 proc append base=y1 data=y&i;
	run;
	
   %end;
run;
%mend;
%try;
run;

/*Creating Final Appended dataset*/
DM 'output;clear;log;clear;';				
Data black.Total;
   merge final  y1 ;
run;

proc reg data=black.hbat_200 (RENAME=(X19=Y)) outest= TESTING COVOUT TABLEOUT ALPHA=.1 ;
   model Y= X9 X12 X13 X14;
run;
data BetasBounds;
  set TESTING;
  where _type_='L90B' OR _type_='U90B' OR _type_='PARMS';
run;
proc transpose data = BetasBounds (DROP=_MODEL_  _TYPE_  _NAME_ _DEPVAR_ _RMSE_ Y ) out = BetasBounds_tp (RENAME=(_NAME_=Parm COL1=BETA COL2=LOWER_BOUND COL3=UPPER_BOUND) DROP=_LABEL_);
    var _ALL_;
run;


proc reg data=black.Total noprint outest= TESTING COVOUT  ;
   model y= X9 X12 X13 X14;
   by _Imputation_;
run;

ods trace on;
Proc MIAnalyze data=TESTING ALPHA=0.3;
   modeleffects intercept  x9 X12 X13 X14;
   ODS OUTPUT ParameterEstimates=MIAnalyzeCoeff /*(KEEP= Parm Estimate )*/;
run;
ods trace OFF;

PROC SORT DATA=BetasBounds_tp; BY Parm;PROC SORT DATA=MIAnalyzeCoeff; BY Parm;RUN;

DATA AllEstimates ;
	MERGE MIAnalyzeCoeff BetasBounds_tp;
	
RUN;

