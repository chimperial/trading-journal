//@version=5
indicator("EMA 34 & 89 Only", overlay=true)

// Input for EMA lengths
tf_ema34 = input.int(34, title="EMA 34 Length", minval=1)
tf_ema89 = input.int(89, title="EMA 89 Length", minval=1)

// Calculate EMAs
ema34 = ta.ema(close, tf_ema34)
ema89 = ta.ema(close, tf_ema89)

// Plot EMAs
plot(ema34, title="EMA 34", color=color.orange, linewidth=2)
plot(ema89, title="EMA 89", color=color.blue, linewidth=2)
