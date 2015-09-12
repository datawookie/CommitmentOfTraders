library(plyr)
library(ggplot2)
library(RColorBrewer)
library(scales)
library(reshape2)

# PARAMETERS --------------------------------------------------------------------------------------

ALPHA = 0.05
#
QUANTILE = 1 - ALPHA / 2

# HELPER FUNCTIONS --------------------------------------------------------------------------------

shift <- function(x, n = 1) {
    if (n == 0) return(x)
    else {
        return(c(rep(NA, n), x[-((length(x)-n+1):length(x))]))
    }
}

# -------------------------------------------------------------------------------------------------

# The proportional changes are normalised relative to the sum of the previous long and short
# values for the currency/sector. Note that we subtract to form this sum since the shorts are
# negative.
#
# Start by putting NA at end, which means that diff lines up with previous value...
#
weekly.delta = ddply(OP, .(name, sector), mutate,
      Long = c(diff(long), NA),
      Short = c(-diff(shrt), NA)
      )
#
# ... use total previous value to normalise (Note capitalisation here: we are normalising the
# diffs to the values)...
#
weekly.delta = transform(weekly.delta,
                Long = Long / (long - shrt),
                Short = Short / (long - shrt)
)
#
weekly.delta = ddply(weekly.delta, .(name, sector), mutate,
            Long = shift(Long),
            Short = shift(Short))
#
weekly.delta$long <- NULL
weekly.delta$shrt <- NULL
#
weekly.delta = weekly.delta[complete.cases(weekly.delta),]
#
weekly.delta = melt(weekly.delta, variable.name = "type", id.vars = c("name", "sector", "date"))

# Restrict to last year
#
weekly.delta = subset(weekly.delta, max.date - weekly.delta$date <= 366)

# Get quantiles
#
weekly.quantile = ddply(weekly.delta, .(name, sector, type), summarize,
                        ymin = quantile(value, probs = 1 - QUANTILE),
                        ymax = quantile(value, probs = QUANTILE))

# Get delta for most recent week
#
last.delta = ddply(weekly.delta, .(name, sector, type), summarise, value = tail(value, 1))

delta.absmax = max(abs(range(last.delta$value, weekly.quantile$ymin, weekly.quantile$ymax)))
delta.limits = rep(delta.absmax, 2) * c(-1, 1)
#
png(sprintf("fig/%s-weekly-change.png", label), width = 800, height = 1000)
ggplot(last.delta, aes(x = type, y = value)) +
    geom_bar(aes(fill = type, alpha = value / delta.absmax), stat = "identity") +
    labs(x = "", title = sprintf("Commitments of Traders (Week ending %s)", strftime(max.date))) +
    scale_y_continuous("Percent Change", labels = percent_format(), breaks = seq(-1, 1, 0.2), limits = delta.limits) +
    geom_crossbar(data = weekly.quantile, aes(y = 0, ymin = ymin, ymax = ymax), colour = "#666666") +
    # geom_hline(data = weekly.quantile, aes(yintercept = quantile), lty = "dashed") +
    # geom_hline(yintercept = 0, lty = "dashed") +
    discrete_scale("fill", "brewer", function(n) {c("#0000FF", "#FF0000")}) +
    facet_grid(name ~ sector) +
    theme_classic() + theme(legend.position = "none", text = element_text(size = 15))
dev.off()

