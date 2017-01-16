# Commitment of Traders for R

## Commitment of Traders Report

The Commitments of Traders (COT) report is issued weekly by the Commodity Futures Trading Commission (CFTC). It reflects the level of activity in the futures markets. The report, which is issued every Friday, contains the data from the previous Tuesday. 

The reports are available in either [long](http://www.cftc.gov/files/dea/cotarchives/2014/futures/deacmelf050614.htm) or [short](http://www.cftc.gov/files/dea/cotarchives/2014/futures/deacmesf050614.htm) format from the [CFTC web site](http://www.cftc.gov/MarketReports/CommitmentsofTraders/HistoricalViewable/index.htm). Just select the date you are interested in and you will be taken through to a page where you can select from a range of reports. You can view the reports online of download the data as a CSV or xls file.

## R Interface

This code was originally documented in a blog post entitled [What Can We Learn from the Commitments of Traders Report?](http://www.exegetic.biz/blog/2014/05/what-can-we-learn-from-the-commitments-of-traders-report/).

At present the code has not been set up as a library. It's just a series of scripts in the `scripts` and `demo` directories. Given time and motivation I will make this into a genuine library. Your feedback will be a good motivation!

## Instructions

1. Execute `0-get-cot-data.sh` from project root folder. This will create a `data/` folder containing the downloaded data files.
2. Execute each of the files in `demo/` in numerical sequence. You'll need to insert a Quandl API key to grab data in the second script.