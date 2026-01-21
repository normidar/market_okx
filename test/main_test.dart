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
      'getKlineHistory fetches candle data with limit <= 300',
      () async {
        const count = 100;
        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1h,
          limit: count,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(count));
      },
    );

    test(
      'getKlineHistory fetches candle data with limit > 300',
      () async {
        const count = 500;
        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1h,
          limit: count,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(count));
        print('Fetched ${candles.length} candles with pagination');
      },
    );

    test(
      'getKlineHistory fetches maximum 1440 candles',
      () async {
        const count = 1440;
        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1h,
          limit: count,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(count));
        print('Fetched ${candles.length} candles at maximum limit');
      },
    );

    test(
      'getKlineHistory throws error when limit exceeds 1440 for recent data',
      () async {
        expect(
          () => market.getKlineHistory(
            instrument: 'BTC-USDT',
            interval: Interval.$1h,
            limit: 1441,
            // No endTime means recent data, which has 1440 limit
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'getKlineHistory throws error when limit is much larger than 1440 for recent data',
      () async {
        expect(
          () => market.getKlineHistory(
            instrument: 'BTC-USDT',
            interval: Interval.$1h,
            limit: 5000,
            // No endTime means recent data, which has 1440 limit
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('1440'),
            ),
          ),
        );
      },
    );

    test(
      'getKlineHistory automatically uses history-candles for old data',
      () async {
        const count = 1500;
        // Use endTime more than 1 hour in the past to trigger history-candles
        // The endpoint is automatically selected based on the timestamp
        final endTime = DateTime.now().subtract(const Duration(hours: 26));

        // This should NOT throw an error because it automatically uses
        // history-candles endpoint which has no 1440 limit
        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1m,
          limit: count,
          endTime: endTime,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(count));
        print(
          'Fetched ${candles.length} historical candles with limit $count (auto-selected history-candles)',
        );
      },
    );

    test(
      'getKlineHistory throws error for limit > 1440 with recent endTime',
      () async {
        // endTime less than 1 hour ago is considered "recent"
        // so the 1440 limit still applies
        final recentEndTime =
            DateTime.now().subtract(const Duration(minutes: 30));

        final candles = await market.getKlineHistory(
          instrument: 'BTC-USDT',
          interval: Interval.$1m,
          limit: 1550,
          endTime: recentEndTime,
        );

        expect(candles, isNotEmpty);
        expect(candles.length, lessThanOrEqualTo(1550));
      },
    );

    tearDown(() {
      market.dispose();
    });
  });
}
