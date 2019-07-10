/***              DESCRIPTION             ***/
/* This macro attempts to identify outliers */
/* based on median deviation distance       */
%macro MAD_DEV(dat/*input data set*/, new_dat, var/*outlier variable*/, group /*How should data be group?*/, num_devs);

*** sort data ***;
proc sort data=&dat. out=&dat._sort;
	by &group.;
run;

*** calculate the median ***;
proc univariate data=&dat._sort noprint;
	var &var.;
	by &group.;
	output out=med n=nfirst nmiss=nummiss max=max_daily_milg min=min_daily_milg
				mean=mean median=median std=stdev;
run;

*** determine the absolute deviations from the sample median ***;
data devmed;
	merge 	&dat._sort 
			med(keep=&group. median);
	by &group.;
	deviate = abs(&var. - median);
run;
proc univariate data=devmed noprint;
	by &group.;
	var deviate;
	output out=devmed2 median=scale;
run;

data devmed3;
	merge 	devmed
			devmed2(keep=&group. scale);
	by &group.;
	if scale ^= 0;
	if deviate > (median + scale*&num_devs.) then outlier_flag=1;
	else if deviate < (median - scale*&num_devs. ) then outlier_flag=1;
	else outlier_flag = 0;
run;

data &new_dat.;
	set devmed3;
	if outlier_flag = 1;
run;

data scale_zero;
	merge 	devmed
			devmed2(keep=&group. scale);
	by &group.;
	if scale = 0;
run;

proc datasets lib=work;
	delete	&dat._sort
			med
			devmed
			devmed2
			devmed3
;
run;

%mend;
