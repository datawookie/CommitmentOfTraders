#!/usr/bin/Rscript

# NB NB NB http://fxtrade.oanda.com/analysis/commitments-of-traders

# http://www.quantshare.com/item-348-commitments-of-traders-historical-data INTERP OF FIELDS

# Using data from the U S Commodity Futures Trading Commission (http://www.cftc.gov/).

library(stringr)
library(ggplot2)
library(reshape2)
library(lubridate)
library(dplyr)

# Ignore column 3 since the date format has changed between old and new data
#
cot.hist <- read.csv("data/COT-history.txt", stringsAsFactors = FALSE, strip.white = TRUE)
cot.2016 <- read.csv("data/COT-2016.txt", stringsAsFactors = FALSE, strip.white = TRUE)
cot.2017 <- read.csv("data/COT-2017.txt", stringsAsFactors = FALSE, strip.white = TRUE)

COT <- bind_rows(cot.hist, cot.2016, cot.2017)

colnames(COT)[1:2] = c("name", "date")

# Dates are interpreted as a number so they can lose their leading zero.
#
COT = transform(COT, date = str_pad(date, width = 6, pad = "0"))

COT$date = as.Date(COT$date, format = "%y%m%d")

# ------------------------------------------------------------------------------

replace.names <- function(before, after) {
	COT[COT[,1] == before, 1] <<- after
}

replace.names("CANADIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE", "CAD")
replace.names("SWISS FRANC - CHICAGO MERCANTILE EXCHANGE", "CHF")
replace.names("BRITISH POUND STERLING - CHICAGO MERCANTILE EXCHANGE", "GBP")
replace.names("JAPANESE YEN - CHICAGO MERCANTILE EXCHANGE", "JPY")
replace.names("AUSTRALIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE", "AUD")
replace.names("NEW ZEALAND DOLLAR - CHICAGO MERCANTILE EXCHANGE", "NZD")
replace.names("EURO FX - CHICAGO MERCANTILE EXCHANGE", "EUR")

COT = COT[order(COT$date),]

CURRENCY = c("EUR", "CAD", "CHF", "GBP", "JPY", "AUD", "NZD")

COT = subset(COT, name %in% CURRENCY)

# ---------------------------------------------------------------------------------------------------------------------

NYEAR = 4

max.date = max(COT$date)
#
label = strftime(max.date, format = "%y%m%d")
#
min.date = max.date - years(NYEAR)

cot.dates = unique(COT$date)

# OPEN POSITIONS ------------------------------------------------------------------------------------------------------

OP = COT[, c("name", "date",
             "Noncommercial.Positions.Long..All.", "Noncommercial.Positions.Short..All.", "Noncommercial.Positions.Spreading..All.",
             "Commercial.Positions.Long..All.", "Commercial.Positions.Short..All.",
             "Nonreportable.Positions.Long..All.", "Nonreportable.Positions.Short..All.")]
#
names(OP)[3:9] = c("xlong", "xshrt", "xsprd", "clong", "cshrt", "slong", "sshrt")
#
# Reportable positions:
#
#   - non-commercial traders / large speculators [x]: Banks and Large Financial Money Managers
#   - commercial traders [c]: Farmers, Hedgers, Producers, Factories and Swap Dealers
#
# Non-reportable positions:
#
#   - small speculators [s]
#
# The spreads represent trades that are placed in both directions. If a traders hold 200 long contracts and 150
# short contracts for the same future contract then 50 contracts will appear in the Long field and 150 contracts
# will appear in the Spread field. 
#
OP = transform(OP,
               xlong = xlong + xsprd,
               xshrt = -xshrt - xsprd,
               cshrt = -cshrt,
               sshrt = -sshrt)
#
OP$xsprd <- NULL
#
OP <- melt(OP, id.vars = c("name", "date"))
#
OP$type <- "shrt"
OP$type[grep("long", OP$variable)] <- "long"
#
OP$sector = sapply(substr(OP$variable, 1, 1), function(n) {
    switch(n, x = "Non-Commercial", c = "Commercial", s = "Small Speculators")}
)
OP$sector = factor(OP$sector)
#
OP$variable <- NULL
#
OP <- dcast(OP, name + date + sector ~ type)
head(OP)

dir.create("fig")

png(sprintf("fig/%s-open-positions.png", label), width = 2000, height = 1200)
ggplot(OP, aes(x = date)) +
    geom_area(aes(y = long / 10000), stat = "identity", fill = "blue") +
    geom_area(aes(y = shrt / 10000), stat = "identity", fill = "red") +
    geom_line(aes(y = (long + shrt) / 10000), size = 1.5) +
    facet_grid(name ~ sector, scales="free") +
    xlab("") + ylab("Positions / 10000") +
    scale_x_date(limits = c(min.date, max.date)) +
    theme_classic() + theme(text = element_text(size = 16), axis.text.x = element_text(angle = 60, hjust = 1))
dev.off()

# OPEN INTEREST -------------------------------------------------------------------------------------------------------

OI = COT[, c("name", "date", "Open.Interest..All.", "Change.in.Open.Interest..All.")]
#
names(OI)[3:4] = c("open.interest", "change.interest")
#
OI$change.interest = as.integer(sub("\\.", NA, OI$change.interest))

png(sprintf("fig/%s-open-interest.png", label), width = 1000, height = 1200)
ggplot(OI, aes(x = date)) +
    geom_line(aes(y = open.interest / 10000)) +
    geom_line(aes(y = change.interest / 10000), colour = "red") +
    facet_grid(name ~ ., scales="free") +
    xlab("") + ylab("Open Interest / 10000") +
    scale_x_date(limits = c(min.date, max.date)) +
    theme_classic() + theme(text = element_text(size = 16))
dev.off()

# ---------------------------------------------------------------------------------------------------------------------
