## 0.0.1

- Initial release
- Implement `Market` interface from `market_interface`
- Support for fetching instruments (spot, futures, perpetual, margin, options)
- Support for fetching OHLCV (candlestick) data
- Support for 16 different timeframes (1m to 1M)
- Automatic pagination for requests exceeding 300 candles
- Automatic endpoint selection (candles vs history-candles)
- Smart handling of OKX API limits (1440 for recent data, unlimited for historical)
- Type-safe implementation with `Decimal` for price data
- Comprehensive test coverage
