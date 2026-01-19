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
      'getKlineHistory throws error when limit exceeds 1440',
      () async {
        expect(
          () => market.getKlineHistory(
            instrument: 'BTC-USDT',
            interval: Interval.$1h,
            limit: 1441,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'getKlineHistory throws error when limit is much larger than 1440',
      () async {
        expect(
          () => market.getKlineHistory(
            instrument: 'BTC-USDT',
            interval: Interval.$1h,
            limit: 5000,
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

    tearDown(() {
      market.dispose();
    });
  });
}
