//@version=5
strategy("RSI Divergence Strategy", overlay=true, initial_capital=10000, default_qty_type=strategy.percent_of_equity, default_qty_value=100)

// Input parameters
rsiLength = input.int(defval=14, title="RSI Length", minval=1)
lookback = input.int(defval=5, title="Divergence Lookback", minval=2)
exitRsiLevel = input.int(defval=70, title="RSI Exit Level", minval=1, maxval=100)
useStopLoss = input.bool(true, title="Use Stop Loss")
stopLossPercent = input.float(2.0, title="Stop Loss %", minval=0.1, step=0.1)
useTakeProfit = input.bool(true, title="Use Take Profit")
takeProfitPercent = input.float(4.0, title="Take Profit %", minval=0.1, step=0.1)

// RSI Calculation
rsiValue = ta.rsi(close, rsiLength)

// Find local lows and highs
isLow = low < ta.lowest(low, lookback)[1] and low < ta.lowest(low, lookback)
isHigh = high > ta.highest(high, lookback)[1] and high > ta.highest(high, lookback)

// Find previous low and high
var float prevLow = na
var float prevRsiLow = na
var float prevHigh = na
var float prevRsiHigh = na

// Detect bullish divergence (price lower low, RSI higher low)
bullDiv = false
if isLow
    if not na(prevLow) and low < prevLow and rsiValue > prevRsiLow
        bullDiv := true
    prevLow := low
    prevRsiLow := rsiValue

// Detect bearish divergence (price higher high, RSI lower high)
bearDiv = false
if isHigh
    if not na(prevHigh) and high > prevHigh and rsiValue < prevRsiHigh
        bearDiv := true
    prevHigh := high
    prevRsiHigh := rsiValue

// === Strategy Entry ===
if bullDiv and (na(strategy.position_size) or strategy.position_size == 0)
    strategy.entry("Long", strategy.long)

// === Strategy Exit ===
exitSignal = bearDiv or (rsiValue > exitRsiLevel)
if exitSignal and strategy.position_size > 0
    strategy.close("Long")

// Stop Loss and Take Profit
if useStopLoss or useTakeProfit
    float stopPrice = na
    float takePrice = na
    if useStopLoss
        stopPrice := strategy.position_avg_price * (1 - stopLossPercent / 100)
    if useTakeProfit
        takePrice := strategy.position_avg_price * (1 + takeProfitPercent / 100)
    strategy.exit("Exit", from_entry="Long", stop=stopPrice, limit=takePrice)

// Plot RSI
plot(rsiValue, color=color.blue, title="RSI")
hline(exitRsiLevel, "RSI Exit Level", color=color.red)

// Plot divergence signals
plotshape(bullDiv, style=shape.triangleup, location=location.belowbar, color=color.green, size=size.small, title="Bullish Divergence")
plotshape(bearDiv, style=shape.triangledown, location=location.abovebar, color=color.red, size=size.small, title="Bearish Divergence")
