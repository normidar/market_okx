# Example Usage

This directory contains examples demonstrating how to use the `market_okx` package.

## Running the Example

```bash
dart run example/main.dart
```

## What the Example Does

The example demonstrates:

1. **Getting supported intervals** - Shows all available timeframes
2. **Fetching spot instruments** - Retrieves all available spot trading pairs
3. **Getting recent candlestick data** - Fetches the latest 10 candles for BTC-USDT
4. **Pagination** - Automatically handles requests for more than 300 candles
5. **Historical data** - Fetches data from 7 days ago (uses history-candles endpoint)
6. **Perpetual swaps** - Retrieves perpetual swap instruments
7. **Simple statistics** - Calculates basic statistics from the candle data

## Expected Output

```
=== OKX Market Data Example ===

1. Supported intervals:
   1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 2d, 3d, 1w, 1M

2. Fetching spot instruments...
   Found 500+ instruments
   First 5: BTC-USDT, ETH-USDT, SOL-USDT, ...

3. Fetching recent BTC-USDT 1h candles (limit: 10)...
   Fetched 10 candles
   Latest candle:
     Open:   50000.0
     High:   50500.0
     Low:    49800.0
     Close:  50300.0
     Volume: 1234.5

...

=== Example completed successfully! ===
```

## Notes

- The example makes real API calls to OKX
- No API key is required for public market data
- The example includes proper error handling and resource cleanup
- All HTTP connections are properly disposed at the end
