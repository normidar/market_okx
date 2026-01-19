import 'package:market_interface/market_interface.dart';
import 'package:market_okx/market_okx.dart';
import 'package:test/test.dart';

void main() {
  group('MarketOkx', () {
    late MarketOkx market;

    setUp(() {
      market = MarketOkx();
    });

    test('getSupportedIntervals returns all OKX intervals', () {
      final intervals = market.getSupportedIntervals();

      expect(intervals, isNotEmpty);
      expect(intervals, contains(Interval.$1m));
      expect(intervals, contains(Interval.$1h));
      expect(intervals, contains(Interval.$1d));
      expect(intervals, contains(Interval.$1w));
    });

    test(
      'getInstruments fetches spot instruments',
      () async {
        final instruments =
            await market.getInstruments(type: InstrumentType.spot);

        expect(instruments, isNotEmpty);
        expect(instruments, isA<List<String>>());
      },
    );

    test(
      'getKlineHistory fetches candle data',
      () async {
        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1h,
          limit: 10,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(10));
      },
    );

    tearDown(() {
      market.dispose();
    });
  });
}
