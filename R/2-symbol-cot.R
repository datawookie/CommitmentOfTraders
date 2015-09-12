library(gridExtra)
library(stringr)
library(Quandl)
library(ggplot2)
library(gridExtra)
library(gtable)

TOKEN = "ZUiqTeUwTRzDyRwpFLyd"

Quandl.auth(TOKEN)

# UTILITIES ---------------------------------------------------------------------------------------

pair.name <- function(currency) {
    switch(currency,
           EUR = "EURUSD",
           CAD = "USDCAD",
           CHF = "USDCHF",
           GBP = "GBPUSD",
           JPY = "USDJPY",
           AUD = "AUDUSD",
           NZD = "NZDUSD")
}

# GET FOREX DATA ----------------------------------------------------------------------------------

forex = list()
#
for (currency in CURRENCY) {
    pair = pair.name(currency)
    #
    cat(currency, " ", pair, "\n")
    
    FX = Quandl(sprintf("QUANDL/%s", pair), start_date = min.date)
    names(FX) = c("date", "close", "high", "low")
    #
    FX$pair = pair
    #
    FX = FX[, c(5, 1, 3, 4, 2)]
    #
    print(head(FX))
    
    forex[[pair]] = FX
}
#
forex = do.call(rbind, forex)
rownames(forex) = 1:nrow(forex)
#
# Missing values (Note that high and low are only estimated, so we really should not use them!)
#
forex = transform(forex,
          high = ifelse(high == 0, NA, high),
          low = ifelse(low == 0, NA, low))

# Consolidated plot of FOREX data for the last N days
#
png(sprintf("fig/%s-forex-recent.png", label, pair), width = 800, height = 800)
ggplot(subset(forex, max.date - date <= 60), aes(x = date)) +
    geom_line(aes(y = close)) +
    facet_grid(pair ~ ., scales = "free") +
    geom_vline(xintercept = as.numeric(tail(cot.dates, 1)), lty = "dashed") +
    scale_x_date(labels = date_format("%d/%m"), breaks = date_breaks("week")) +
    xlab("") + ylab("") +
    theme_classic() + theme(text = element_text(size = 15))
dev.off()

# FOREX DATA --------------------------------------------------------------------------------------

# NOTE: FOREX data are daily while COT is weekly!

for (currency in CURRENCY) {
    pair = pair.name(currency)
    cat(currency, " ", pair, "\n")
    
    # Take into account whether or not USD is the base currency.
    #
    if (str_locate(pair, "USD")[1,1] == 1) {factor = -1} else {factor = +1}
    
    p1 = ggplot(forex[forex$pair == pair,], aes(x = date)) +
        geom_line(aes(y = close), size = 1.5) +
        xlab("") + ylab(pair) +
        scale_x_date(limits = c(min.date, max.date)) +
        theme_classic() + theme(text = element_text(size = 15), axis.text.x = element_blank())
    
    p2 = ggplot(subset(OP, name == currency), aes(x = date)) +
        geom_line(aes(y = factor * (long + shrt) / 10000, group = sector, colour = sector)) +
        geom_hline(yintercept = 0, lty = "dashed") +
        xlab("") + ylab("Positions / 10000") +
        scale_x_date(limits = c(min.date, max.date)) +
        theme_classic() + theme(text = element_text(size = 15), legend.position = "none", axis.text.x = element_blank())
    
    # Note that shrt is negative, so we are effectively doing (long - |shrt|) / (long + |shrt|)
    p4 = ggplot(subset(OP, name == currency), aes(x = date)) +
        geom_line(aes(y = factor * (long + shrt) / (long - shrt), group = sector, colour = sector)) +
        geom_hline(yintercept = 0, lty = "dashed") +
        xlab("") + 
        scale_x_date(limits = c(min.date, max.date)) +
        scale_y_continuous("Sentiment", limits = c(-1, 1), breaks = c(-1, 1), labels = c("Bearish", "Bullish")) +
        theme_classic() + theme(text = element_text(size = 15)) +
        theme(legend.position = "bottom", legend.title = element_blank(), axis.text.y = element_text(angle = 90, hjust = 0.5))
    
    p3 = ggplot(subset(OI, name == currency), aes(x = date)) +
        geom_line(aes(y = open.interest / 10000)) +
        geom_line(aes(y = change.interest / 10000), colour = "red") +
        xlab("") + ylab("Open Interest / 10000") +
        scale_x_date(limits = c(min.date, max.date)) +
        theme_classic() + theme(text = element_text(size = 15), axis.text.x = element_blank())
    
    # Make size of plots such that x-axes are aligned
    #
    p1 <- ggplot_gtable(ggplot_build(p1))
    p2 <- ggplot_gtable(ggplot_build(p2))
    p3 <- ggplot_gtable(ggplot_build(p3))
    p4 <- ggplot_gtable(ggplot_build(p4))
    maxWidth = unit.pmax(p1$widths[2:3], p2$widths[2:3], p3$widths[2:3], p4$widths[2:3])
    #
    p1$widths[2:3] <- maxWidth
    p2$widths[2:3] <- maxWidth
    p3$widths[2:3] <- maxWidth
    p4$widths[2:3] <- maxWidth
    
    png(sprintf("fig/%s-%s.png", label, pair), width = 1000, height = 800)
    grid.arrange(p1, p3, p2, p4, nrow = 4, heights = c(1, 1, 1, 1.5))
    dev.off()
}

# -------------------------------------------------------------------------------------------------

