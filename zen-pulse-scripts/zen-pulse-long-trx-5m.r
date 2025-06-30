//@version=5
strategy("(Long) Zen Pulse by ChillBits", overlay=true, initial_capital=10000, default_qty_type=strategy.percent_of_equity, default_qty_value=100)

// === Fixed Parameters ===
minStopLossPercent   = 0.1 / 100
maxStopLossPercent   = 0.84 / 100
minVolatilityPercent = 0.1 / 100
maxVolatilityPercent = 100 / 100
rrRatio              = 1
rrMinRatio           = 0.6
lookback             = 300
EMA                  = 89
HiLoLen              = 34

// === Input Parameters ===
//minStopLossPercent   = input.float(0.1,  "Min Stop Loss %",        minval=0.1) / 100
//maxStopLossPercent   = input.float(100,    "Max Stop Loss %",        minval=0.1) / 100
//minVolatilityPercent = input.float(0.1,  "Min Volatility Range %", minval=0.1) / 100
//maxVolatilityPercent = input.float(100,   "Max Volatility Range %", minval=0.1) / 100
//rrRatio              = input.float(1,    "Risk/Reward Ratio",      minval=0.1)
//rrMinRatio           = input.float(0.7, "Min Risk/Reward Ratio", minval=0.01)
//lookback             = input.int(300,    "Look back range",        minval=1)
//EMA                  = input.int(89,     title="EMA Signal",        minval=1)
//HiLoLen              = input.int(34,     title="High Low channel Length", minval=2)

// === PAC Channel Calculations ===
pacC = ta.ema(close, HiLoLen)
pacL = ta.ema(low,   HiLoLen)
pacH = ta.ema(high,  HiLoLen)

// === Colors ===
var color DODGERBLUE = color.new(#1E90FF, 0)

// === Plotting PAC Channel ===
plot(pacL, color=color.new(DODGERBLUE, 50), linewidth=1, title="High PAC EMA")
plot(pacH, color=color.new(DODGERBLUE, 50), linewidth=1, title="Low PAC EMA")
plot(pacC, color=color.new(DODGERBLUE, 0),  linewidth=1, title="Close PAC EMA")
fill(plot(pacL), plot(pacH), color=color.new(color.aqua, 90), title="Fill HiLo PAC")

// === Moving Averages ===
signalMA = ta.ema(close, EMA)
ema610   = ta.ema(close, 610)
ema200   = ta.ema(close, 200)

plot(ema610,   title="EMA 610",   color=color.white,   linewidth=1)
plot(ema200,   title="EMA 200",   color=color.fuchsia, linewidth=1)
plot(signalMA, title="EMA Signal", color=color.orange,  linewidth=1)

// === Lookback Highs and Lows ===
lowestLow  = ta.lowest(low,  lookback)
highestHigh = ta.highest(high, lookback)

plot(lowestLow,  title="Lowest Low (300 bars)",  color=color.red,  linewidth=1)
plot(highestHigh, title="Highest High (300 bars)", color=color.blue, linewidth=1)

// === Entry Signal: Price Crosses Above PAC High ===
entry_above_pacH = close > pacH and close[1] <= pacH[1]
entry_close      = entry_above_pacH ? close : na
plot(entry_close, title="Entry Above PAC Channel", color=color.green, linewidth=1, style=plot.style_line)

// === Entry Condition Parts ===
cond_entry_above_pacH   = entry_above_pacH
cond_lowestLow_not_na   = not na(lowestLow)
cond_highestHigh_not_na = not na(highestHigh)
cond_flat_position      = strategy.position_size == 0
cond_max_stop_loss      = (close - lowestLow) / close < maxStopLossPercent
cond_min_stop_loss      = (close - lowestLow) / close > minStopLossPercent
cond_risk_vs_reward     = (highestHigh - close) / (close - lowestLow) > rrMinRatio
cond_min_volatility     = (highestHigh - lowestLow) / close > minVolatilityPercent
cond_max_volatility     = (highestHigh - lowestLow) / close < maxVolatilityPercent

// Merge min and max stop loss into one stop_loss_range condition
stop_loss_range = (close - lowestLow) / close > minStopLossPercent and (close - lowestLow) / close < maxStopLossPercent

// Merge min and max volatility into one volatility_range condition
volatility_range = (highestHigh - lowestLow) / close > minVolatilityPercent and (highestHigh - lowestLow) / close < maxVolatilityPercent

entry_condition =cond_entry_above_pacH
 and cond_lowestLow_not_na
 and cond_highestHigh_not_na
 and cond_flat_position
 and stop_loss_range
 and cond_risk_vs_reward
 and volatility_range

// === Strategy Entry and Exit Logic ===
var float entry_price = na
var float stop_price  = na
var float tp          = na

if entry_condition
    entry_price := close
    sl         = entry_price - lowestLow
    stop_price := lowestLow
    tp         := entry_price + sl * rrRatio
    strategy.entry("Long", strategy.long)

if strategy.position_size > 0
    strategy.exit("Exit", from_entry="Long", stop=stop_price, limit=tp)

