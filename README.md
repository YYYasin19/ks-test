# 2-sample Kolmogorov Smirnov Test

This repository holds the SQL-only code for the 2-sample Kolmogorov Smirnov test.
It was created to help others (you?) find this more easily, as there are only few SQL solutions available on the internet right now.

## Why SQL?
For smaller datasets it might be just easier to load all data into your programming environment, e.g. `python`, and then just call a ready implementation such as `scipy.stats.ks_2samp`.
Unfortunately, this option is not viable for datasets with more than a few million rows.
Here, calculating the KS statistic might take up a few minutes on modern machines, most of which is just spent transferring data.

## Usage
To calculate the KS test statistic $d$ between two data samples, you just have to replace the most inner queries in the first steps.
Since all subsequent queries are only referencing aliases etc. this should be all at this point.
Note: Until now, this has only been tried for samples containing numerical, non-null values.

## Theory & References

This was created during the implementation of the test for our [datajudge](https://github.com/Quantco/datajudge/pull/28) project.
There, I also explain the idea behind the test and this code.


