//@version=5
strategy("Zen Pulse by ChillBits (Hedge)", overlay=true, initial_capital=10000, default_qty_type=strategy.percent_of_equity, default_qty_value=100)

// Input parameters
maxStopLossPercentLong = input.float(4, "Max Stop Loss % (Long)", minval = 0.1) / 100
minStopLossPercentLong = input.float(0.1, "Min Stop Loss % (Long)", minval = 0.1) / 100
minVolatilityPercentLong = input.float(0.1, "Min Volatility Range % (Long)", minval = 0.1) / 100
maxVolatilityPercentLong = input.float(20, "Max Volatility Range % (Long)", minval = 0.1) / 100
rrRatioLong = input.float(1, "Risk/Reward Ratio (Long)", minval = 0.1)
lookback = input.int(300, "Look back range", minval=1)
EMA = input.int(defval=89, title="EMA Signal", minval=1)
HiLoLen = input.int(34, title="High Low channel Length", minval=2)

maxStopLossPercentShort = input.float(4, "Max Stop Loss % (Short)", minval = 0.1) / 100
minStopLossPercentShort = input.float(0.1, "Min Stop Loss % (Short)", minval = 0.1) / 100
minVolatilityPercentShort = input.float(0.1, "Min Volatility Range % (Short)", minval = 0.1) / 100
maxVolatilityPercentShort = input.float(20, "Max Volatility Range % (Short)", minval = 0.1) / 100
rrRatioShort = input.float(1, "Risk/Reward Ratio (Short)", minval = 0.1)

// PAC Channel calculations
pacC = ta.ema(close, HiLoLen)
pacL = ta.ema(low, HiLoLen)
pacH = ta.ema(high, HiLoLen)

// Colors
var color DODGERBLUE = color.new(#1E90FF, 0)

// Plotting
plot(pacL, color=color.new(DODGERBLUE, 50), linewidth=1, title="High PAC EMA")
plot(pacH, color=color.new(DODGERBLUE, 50), linewidth=1, title="Low PAC EMA")
plot(pacC, color=color.new(DODGERBLUE, 0), linewidth=1, title="Close PAC EMA")
fill(plot(pacL), plot(pacH), color=color.new(color.aqua, 90), title="Fill HiLo PAC")

// Moving Averages
signalMA = ta.ema(close, EMA)
ema610 = ta.ema(close, 610)
ema200 = ta.ema(close, 200)

plot(ema610, title="EMA 610", color=color.white, linewidth=1)
plot(ema200, title="EMA 200", color=color.fuchsia, linewidth=1)
plot(signalMA, title="EMA Signal", color=color.orange, linewidth=1)

// Find the lowest low of the previous 300 closed bars
lowestLow = ta.lowest(low, lookback)

// Find the highest high of the previous 300 closed bars
highestHigh = ta.highest(high, lookback)

// Optionally, plot or display the lowest low value
plot(lowestLow, title="Lowest Low (300 bars)", color=color.red, linewidth=1)
plot(highestHigh, title="Highest High (300 bars)", color=color.blue, linewidth=1)

// Mark the close price whenever price moves from under the PAC channel to above the PAC channel (Long Entry)
entry_above_pacH = close > pacH and close[1] <= pacH[1]
entry_close_long = entry_above_pacH ? close : na
plot(entry_close_long, title="Entry Above PAC Channel", color=color.green, linewidth=1, style=plot.style_line)

// Mark the close price whenever price moves from above the PAC channel to below the PAC channel (Short Entry)
entry_below_pacL = close < pacL and close[1] >= pacL[1]
entry_close_short = entry_below_pacL ? close : na
plot(entry_close_short, title="Entry Below PAC Channel", color=color.red, linewidth=1, style=plot.style_line)

// Strategy entry and exit logic for Long
var float entry_price_long = na
var float stop_price_long = na
var float tp_long = na

if entry_above_pacH and not na(lowestLow) and not na(highestHigh) and (close - lowestLow) / close < maxStopLossPercentLong and (close - lowestLow) / close > minStopLossPercentLong and (close - lowestLow) < (highestHigh - close) and (highestHigh - lowestLow) / close > minVolatilityPercentLong and (highestHigh - lowestLow) / close < maxVolatilityPercentLong
    entry_price_long := close
    sl_long = entry_price_long - lowestLow  // Stop loss distance
    stop_price_long := lowestLow
    tp_long := entry_price_long + sl_long * rrRatioLong     // Take profit
    strategy.entry("Long", strategy.long)

strategy.exit("Exit Long", from_entry="Long", stop=stop_price_long, limit=tp_long)

// Strategy entry and exit logic for Short
var float entry_price_short = na
var float stop_price_short = na
var float tp_short = na

if entry_below_pacL and not na(lowestLow) and not na(highestHigh) and (highestHigh - close) / close < maxStopLossPercentShort and (highestHigh - close) / close > minStopLossPercentShort and (highestHigh - close) < (close - lowestLow) and (highestHigh - lowestLow) / close > minVolatilityPercentShort and (highestHigh - lowestLow) / close < maxVolatilityPercentShort
    entry_price_short := close
    sl_short = highestHigh - entry_price_short  // Stop loss distance
    stop_price_short := highestHigh
    tp_short := entry_price_short - sl_short * rrRatioShort     // Take profit
    strategy.entry("Short", strategy.short)

strategy.exit("Exit Short", from_entry="Short", stop=stop_price_short, limit=tp_short)

