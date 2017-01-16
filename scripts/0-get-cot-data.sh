#!/bin/bash

# ------------------------------------------------------------------------------

# A directory to the data can be found at:
#
# http://www.cftc.gov/MarketReports/CommitmentsofTraders/HistoricalCompressed/index.htm
#
# This is the old data:
#
# http://www.cftc.gov/files/dea/history/fut_fin_txt_2006_2013.zip
#
# It is stored as "COT-history.txt"

# Used to use these files (available from same directory):
#
# 	fut_fin_txt_2006_2013.zip
# 	fut_fin_txt_2014.zip
#
# but the breakdown of the data was done in a weird way.

# ------------------------------------------------------------------------------

mkdir -p data

HISTORY=data/COT-history.txt

if [ ! -f $HISTORY ]
then
	DATAZIP=deacot1986_2015.zip
	wget http://www.cftc.gov/files/dea/history/$DATAZIP
	unzip $DATAZIP
	rm -f $DATAZIP
	mv FUT86_15.txt $HISTORY
else
	echo "got historical data..."
fi

for YEAR in 2016 2017
do
	DATAZIP=deacot${YEAR}.zip
  #
	wget http://www.cftc.gov/files/dea/history/$DATAZIP

	DATATXT=annual.txt
  #
	rm -f $DATATXT
  #
	unzip $DATAZIP
	rm -f $DATAZIP

	mv $DATATXT data/COT-${YEAR}.txt
done
