# market_okx

[![GitHub](https://img.shields.io/github/license/normidar/market_okx.svg)](https://github.com/normidar/market_okx/blob/main/LICENSE)
[![pub package](https://img.shields.io/pub/v/market_okx.svg)](https://pub.dartlang.org/packages/market_okx)
[![GitHub Stars](https://img.shields.io/github/stars/normidar/market_okx.svg)](https://github.com/normidar/market_okx/stargazers)
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/normidar.svg?style=social&label=Follow%20%40normidar)](https://twitter.com/normidar)
[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/normidar)

A Dart package for accessing OKX market data. Part of the Coin Galaxy ecosystem.

## Features

- Fetch market instruments (spot, futures, perpetual swaps, margin, options)
- Get historical OHLCV (candlestick) data
- Support for multiple timeframes (1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 2d, 3d, 1w, 1M)
- Automatic pagination for large data requests
- Automatic endpoint selection for historical vs recent data
- Type-safe implementation with `market_interface`

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  market_okx: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Example

```dart
import 'package:market_okx/market_okx.dart';
import 'package:market_interface/market_interface.dart';

void main() async {
  // Create a market instance
  final market = MarketOkx();

  try {
    // Get all spot instruments
    final instruments = await market.getInstruments(
      type: InstrumentType.spot,
    );
    print('Available instruments: ${instruments.length}');

    // Get candlestick data
    final candles = await market.getKlineHistory(
      instrument: 'BTC-USDT',
      interval: Interval.$1h,
      limit: 100,
    );
    print('Fetched ${candles.length} candles');

    // Access OHLCV data
    for (final candle in candles.take(5)) {
      print('Open: ${candle.open}, Close: ${candle.close}, Volume: ${candle.volume}');
    }
  } finally {
    // Don't forget to dispose
    market.dispose();
  }
}
```

### Fetching Historical Data

```dart
// Fetch data from a specific time period
final endTime = DateTime.now().subtract(const Duration(days: 7));
final candles = await market.getKlineHistory(
  instrument: 'ETH-USDT',
  interval: Interval.$1h,
  limit: 500,
  endTime: endTime,
);
```

### Supported Intervals

```dart
final intervals = market.getSupportedIntervals();
// Returns: [1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 2d, 3d, 1w, 1M]
```

### Supported Instrument Types

- `InstrumentType.spot` - Spot trading pairs
- `InstrumentType.perpetual` - Perpetual swaps
- `InstrumentType.futures` - Futures contracts
- `InstrumentType.margin` - Margin trading
- `InstrumentType.options` - Options contracts

## API Limits

- For recent data (within 3 intervals of current time): maximum 1440 candles
- For historical data: no limit (automatically uses history-candles endpoint)
- Single request limit: 300 candles (automatically paginated for larger requests)

## Dependencies

This package depends on:

- `market_interface` - Common interface for market data providers
- `finance_kline_core` - Core types for financial data
- `decimal` - Precise decimal arithmetic
- `http` - HTTP client

## Testing

Run tests with:

```bash
dart test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- GitHub Issues: [https://github.com/normidar/market_okx/issues](https://github.com/normidar/market_okx/issues)
- Twitter: [@normidar](https://twitter.com/normidar)
- GitHub Sponsors: [Sponsor this project](https://github.com/sponsors/normidar)
