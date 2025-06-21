//@version=5
strategy("Sonic R Strategy", overlay=true, initial_capital=10000, default_qty_type=strategy.percent_of_equity, default_qty_value=100)

// Input parameters
maxStopLossPercent = input.float(6, "Max Stop Loss %", minval = 0.1) / 100
minStopLossPercent = input.float(3, "Min Stop Loss %", minval = 0.1) / 100
minVolatilityPercent = input.float(5, "Min Volatility Range %", minval = 0.1) / 100
maxVolatilityPercent = input.float(10, "Max Volatility Range %", minval = 0.1) / 100
rrRatio = input.float(1.4, "Risk/Reward Ratio", minval = 0.1)
lookback = input.int(300, "Look back range", minval=1)
EMA = input.int(defval=89, title="EMA Signal", minval=1)
HiLoLen = input.int(34, title="High Low channel Length", minval=2)

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

// Mark the close price whenever price moves from under the PAC channel to above the PAC channel
entry_above_pacH = close > pacH and close[1] <= pacH[1]
entry_close = entry_above_pacH ? close : na
plot(entry_close, title="Entry Above PAC Channel", color=color.green, linewidth=1, style=plot.style_line)

// Strategy entry and exit logic
var float entry_price = na
var float stop_price = na
var float tp = na

if entry_above_pacH and not na(lowestLow) and not na(highestHigh) and strategy.position_size == 0 and (close - lowestLow) / close < maxStopLossPercent and (close - lowestLow) / close > minStopLossPercent and (close - lowestLow) < (highestHigh - close) and (highestHigh - lowestLow) / close > minVolatilityPercent and (highestHigh - lowestLow) / close < maxVolatilityPercent
    entry_price := close
    sl = entry_price - lowestLow  // Stop loss distance
    stop_price := lowestLow
    tp := entry_price + sl * rrRatio     // Take profit
    strategy.entry("Long", strategy.long)

if strategy.position_size > 0
    strategy.exit("Exit", from_entry="Long", stop=stop_price, limit=tp)

