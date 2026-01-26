import 'package:decimal/decimal.dart';
import 'package:market_interface/market_interface.dart';
import 'package:market_okx/market_okx.dart';

Future<void> main() async {
  // Create a market instance
  final market = MarketOkx();

  try {
    // ignore: avoid_print
    print('=== OKX Market Data Example ===\n');

    // 1. Get supported intervals
    // ignore: avoid_print
    print('1. Supported intervals:');
    final intervals = market.getSupportedIntervals();
    // ignore: avoid_print
    print('   ${intervals.join(', ')}\n');

    // 2. Get all spot instruments
    // ignore: avoid_print
    print('2. Fetching spot instruments...');
    final instruments = await market.getInstruments(
      type: InstrumentType.spot,
    );
    // ignore: avoid_print
    print('   Found ${instruments.length} instruments');
    // ignore: avoid_print
    print('   First 5: ${instruments.take(5).join(', ')}\n');

    // 3. Get recent candlestick data
    // ignore: avoid_print
    print('3. Fetching recent BTC-USDT 1h candles (limit: 10)...');
    final recentCandles = await market.getKlineHistory(
      instrument: 'BTC-USDT',
      interval: Interval.$1h,
      limit: 10,
    );
    // ignore: avoid_print
    print('   Fetched ${recentCandles.length} candles');
    if (recentCandles.isNotEmpty) {
      final latest = recentCandles.first;
      // ignore: avoid_print
      print('   Latest candle:');
      // ignore: avoid_print
      print('     Open:   ${latest.open}');
      // ignore: avoid_print
      print('     High:   ${latest.high}');
      // ignore: avoid_print
      print('     Low:    ${latest.low}');
      // ignore: avoid_print
      print('     Close:  ${latest.close}');
      // ignore: avoid_print
      print('     Volume: ${latest.volume}\n');
    }

    // 4. Get candlestick data with pagination (> 300 candles)
    // ignore: avoid_print
    print('4. Fetching BTC-USDT 1h candles with pagination (limit: 500)...');
    final paginatedCandles = await market.getKlineHistory(
      instrument: 'BTC-USDT',
      interval: Interval.$1h,
      limit: 500,
    );
    // ignore: avoid_print
    print('   Fetched ${paginatedCandles.length} candles with pagination\n');

    // 5. Get historical data (automatically uses history-candles endpoint)
    // ignore: avoid_print
    print('5. Fetching historical BTC-USDT 1m candles...');
    final historicalEndTime = DateTime.now().subtract(const Duration(days: 7));
    final historicalCandles = await market.getKlineHistory(
      instrument: 'BTC-USDT',
      interval: Interval.$1m,
      limit: 500,
      endTime: historicalEndTime,
    );
    // ignore: avoid_print
    print('   Fetched ${historicalCandles.length} historical candles');
    // ignore: avoid_print
    print('   (automatically used history-candles endpoint)\n');

    // 6. Get perpetual swap instruments
    // ignore: avoid_print
    print('6. Fetching perpetual swap instruments...');
    final swapInstruments = await market.getInstruments(
      type: InstrumentType.perpetual,
    );
    // ignore: avoid_print
    print('   Found ${swapInstruments.length} swap instruments');
    // ignore: avoid_print
    print('   First 5: ${swapInstruments.take(5).join(', ')}\n');

    // 7. Calculate simple statistics
    if (recentCandles.length >= 2) {
      // ignore: avoid_print
      print('7. Simple statistics for recent candles:');
      final closes = recentCandles.map((c) => c.close).toList();
      final highest = closes.reduce((a, b) => a > b ? a : b);
      final lowest = closes.reduce((a, b) => a < b ? a : b);
      final sum = closes.fold(closes.first, (a, b) => a + b);
      final average = sum / Decimal.fromInt(closes.length);

      // ignore: avoid_print
      print('   Highest close: $highest');
      // ignore: avoid_print
      print('   Lowest close:  $lowest');
      // ignore: avoid_print
      print('   Average close: $average');
    }

    // ignore: avoid_print
    print('\n=== Example completed successfully! ===');
  } on Exception catch (e, stackTrace) {
    // ignore: avoid_print
    print('Error occurred: $e');
    // ignore: avoid_print
    print('Stack trace: $stackTrace');
  } finally {
    // Don't forget to dispose the HTTP client
    market.dispose();
  }
}
