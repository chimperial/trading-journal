//@version=5
indicator("ZPL TRX 1m", overlay=true)

// === Fixed Parameters ===
minStopLossPercent   = 1.1 / 100
maxStopLossPercent   = 1.4 / 100
minVolatilityPercent = 0.1 / 100
maxVolatilityPercent = 100 / 100
rrRatio              = 1.3
rrMinRatio           = 0.1
lookback             = 300
EMA                  = 89
HiLoLen              = 34
slBufferPercent      = 0.01 / 100

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

// === RSI Calculation ===
rsiLength = 14  // Standard RSI period
rsiValue = ta.rsi(close, rsiLength)

plot(ema610,   title="EMA 610",   color=color.white,   linewidth=1)
plot(ema200,   title="EMA 200",   color=color.fuchsia, linewidth=1)
plot(signalMA, title="EMA Signal", color=color.orange,  linewidth=1)

// === Lookback Highs and Lows ===
lowestLow   = ta.lowest(low,  lookback)
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
cond_flat_position      = true  // Always true in indicator
cond_max_stop_loss      = (close - lowestLow) / close < maxStopLossPercent
cond_min_stop_loss      = (close - lowestLow) / close > minStopLossPercent
cond_risk_vs_reward     = (highestHigh - close) / (close - lowestLow) > rrMinRatio
cond_min_volatility     = (highestHigh - lowestLow) / close > minVolatilityPercent
cond_max_volatility     = (highestHigh - lowestLow) / close < maxVolatilityPercent

// Merge min and max stop loss into one stop_loss_range condition
stop_loss_range = (close - lowestLow) / close > minStopLossPercent and (close - lowestLow) / close < maxStopLossPercent

// Merge min and max volatility into one volatility_range condition
volatility_range = (highestHigh - lowestLow) / close > minVolatilityPercent and (highestHigh - lowestLow) / close < maxVolatilityPercent

// === Final Entry Condition ===
entry_condition = cond_entry_above_pacH
 and cond_lowestLow_not_na
 and cond_highestHigh_not_na
 and cond_flat_position
 and stop_loss_range
 and cond_risk_vs_reward
 and volatility_range

// === Indicator Entry/Exit Signals ===
var float entry_price = na
var float stop_price  = na
var float tp          = na

if entry_condition
    entry_price := close
    sl         = entry_price - lowestLow
    stop_price := lowestLow * (1 - slBufferPercent)
    tp         := entry_price + sl * rrRatio

// Plot entry signal
plotshape(entry_condition, title="Long Entry", style=shape.triangleup, location=location.belowbar, color=color.green, size=size.small)

// Plot stop loss and take profit levels when in a 'virtual' position
show_levels = entry_condition or (not na(entry_price) and close >= stop_price and close <= tp)
plot(show_levels ? stop_price : na, title="Stop Loss", color=color.red, linewidth=1, style=plot.style_circles)
plot(show_levels ? tp : na, title="Take Profit", color=color.green, linewidth=1, style=plot.style_circles)

// Add RSI label at entry
if entry_condition
    label.new(bar_index, high, text = "RSI: " + str.tostring(rsiValue, format.percent), color=color.blue, style=label.style_label_down, textcolor=color.white)

// Alert for long entry
alertcondition(entry_condition, title="ZPL TON 5m Long Entry", message="ZPL TON 5m Long Entry Signal: All conditions met for a long position.") 