//@version=5
indicator(title="Kaufman Moving Average Adaptive (KAMA) with SMA and LRC", shorttitle="KAMA", overlay=true)

// Input parameters
Length = input.int(20, minval=1, title="KAMA Length")
sma_length = input.int(200, title="SMA Length")
lrc_length = input.int(40, title="LRC Length")
distance_period = input.int(100, title="Mean Distance Period", tooltip="Number of periods for mean distance calculation")

// Function to calculate KAMA
calc_kama(src, length) =>
    xvnoise = math.abs(src - src[1])  // Noise calculation
    nAMA = 0.0
    nfastend = 0.666  // Fast end constant
    nslowend = 0.0645  // Slow end constant
    nsignal = math.abs(src - src[length])
    
    // Manual noise calculation using a for loop
    var float nnoise = na  // Initialize noise variable
    if bar_index >= length
        nnoise := 0.0  // Reset noise
        for i = 0 to length - 1
            nnoise := nnoise + math.abs(src[i] - src[i + 1])

    // Calculate Efficiency Ratio (ER)
    nefratio = (nnoise != 0) ? nsignal / nnoise : 0

    // Calculate the smoothing factor (nsmooth)
    nsmooth = math.pow(nefratio * (nfastend - nslowend) + nslowend, 2)

    // Update KAMA value
    var float nAMA_var = na  // Declare nAMA variable
    nAMA_var := na(nAMA_var[1]) ? src : nAMA_var[1] + nsmooth * (src - nAMA_var[1])
    
    nAMA_var

// Get 5-minute and 1-hour close prices
close_5m = request.security(syminfo.tickerid, "5", close)
close_1h = request.security(syminfo.tickerid, "60", close)

// Get KAMA, SMA, and LRC for the current timeframe
nAMA_var = calc_kama(close, Length)
sma_current = ta.sma(close, sma_length)
lrc_current = ta.linreg(close, lrc_length, 0)

// Get values for KAMA, SMA, and LRC in 5 minutes (use 'close', as request.security automatically adjusts timeframe)
kama_5m = request.security(syminfo.tickerid, "5", calc_kama(close, Length))
sma_5m = request.security(syminfo.tickerid, "5", ta.sma(close, sma_length))
lrc_5m = request.security(syminfo.tickerid, "5", ta.linreg(close, lrc_length, 0))

// Get values for KAMA, SMA, and LRC in 1 hour (use 'close', as request.security automatically adjusts timeframe)
kama_1h = request.security(syminfo.tickerid, "60", calc_kama(close, Length))
sma_1h = request.security(syminfo.tickerid, "60", ta.sma(close, sma_length))
lrc_1h = request.security(syminfo.tickerid, "60", ta.linreg(close, lrc_length, 0))

// Plot KAMA for the current timeframe
plot(nAMA_var, color=color.rgb(186, 22, 192), title="KAMA (Current)")
plot(sma_current, color=#ecf022, title="SMA (5m)", linewidth=1)
plot(lrc_current, color=#37ade4, title="LRC (5m)", linewidth=1)

// Plot KAMA for 5m and 1h
// plot(kama_5m, color=color.rgb(186, 22, 192), title="KAMA (5m)", linewidth=1)
// plot(kama_1h, color=color.orange, title="KAMA (1h)", linewidth=1)

// Plot 5m SMA and LRC
// plot(sma_5m, color=#ecf022, title="SMA (5m)", linewidth=1)
// plot(lrc_5m, color=#37ade4, title="LRC (5m)", linewidth=1)

// // Plot 1h SMA and LRC
// plot(sma_1h, color=color.gray, title="SMA (1h)", linewidth=1)
// plot(lrc_1h, color=color.teal, title="LRC (1h)", linewidth=1)

// Define buy and sell signals for 1 hour
sell_signal_1h = (close_1h > sma_1h) and (close_1h < lrc_1h) and (close_1h > kama_1h)
buy_signal_1h = (close_1h < sma_1h) and (close_1h > lrc_1h) and (close_1h < kama_1h)

// Define buy and sell signals for 5 minutes using the 5-minute close
sell_signal_5m = (close_5m < lrc_5m) and (close_5m > kama_5m)
buy_signal_5m = (close_5m > lrc_5m) and (close_5m < kama_5m)

// Define convergence signals for both 1-hour and 5-minute timeframes
converging_sell_signal = sell_signal_1h and sell_signal_5m
converging_buy_signal = buy_signal_1h and buy_signal_5m

// // Plot buy and sell signals on the chart for 1 hour
// plotshape(sell_signal_1h, style=shape.circle, location=location.abovebar, color=color.rgb(238, 23, 105), size=size.tiny, title="Sell Signal (1h)")
// plotshape(buy_signal_1h, style=shape.circle, location=location.belowbar, color=#0de94f, size=size.tiny, title="Buy Signal (1h)")

// // Plot buy and sell signals on the chart for 5 minutes
// plotshape(sell_signal_5m, style=shape.triangledown, location=location.abovebar, color=color.red, size=size.small, title="Sell Signal (5m)")
// plotshape(buy_signal_5m, style=shape.triangleup, location=location.belowbar, color=color.green, size=size.small, title="Buy Signal (5m)")

// Plot the signals on the chart using small dots
plot(converging_sell_signal ? high * 1.002 : na, color=#f6ff7d, linewidth=2, style=plot.style_circles, title="Sell Signal (1h)")
plot(converging_buy_signal ? low * 0.998 : na, color=color.rgb(216, 133, 255), linewidth=2, style=plot.style_circles, title="Buy Signal (1h)")

// -------------------- Overextension Logic -------------------- //
// Calculate the distance between the close and the SMA
distance_to_sma_1h = close_1h - sma_1h

// Compute the mean of the distance over a specified period
mean_distance_1h = ta.sma(math.abs(distance_to_sma_1h), distance_period)

// Define overextended conditions (when the price is above or below the mean distance)
overextended_above_1h = close_1h > (sma_1h + mean_distance_1h)
overextended_below_1h = close_1h < (sma_1h - mean_distance_1h)

// Plot the overextended signals on the chart
bgcolor(overextended_above_1h ? #e6ae6533 : na, title="Overextended Above")
bgcolor(overextended_below_1h ? color.rgb(81, 160, 250, 80) : na, title="Overextended Below")

// -------------------- Overextension Logic -------------------- //
// Calculate the distance between the close and the SMA
distance_to_sma = close - ta.sma(close, sma_length)

// Compute the mean of the distance over a specified period
mean_distance = ta.sma(math.abs(distance_to_sma), distance_period)

// Define overextended conditions (when the price is above or below the mean distance)
overextended_above = close > (ta.sma(close, sma_length) + mean_distance)
overextended_below = close < (ta.sma(close, sma_length) - mean_distance)

// Subtle overextended signals using small dots
plot(overextended_above ? high * 1.0005 : na, color=#f35d21, linewidth=2, style=plot.style_steplinebr, title="Sell Signal (1h)")
plot(overextended_below ? low * 0.9995 : na, color=#00d458, linewidth=2, style=plot.style_steplinebr, title="Buy Signal (1h)")


