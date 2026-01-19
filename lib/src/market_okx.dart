import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:finance_kline_core/finance_kline_core.dart';
import 'package:http/http.dart' as http;
import 'package:market_interface/market_interface.dart';

class MarketOkx extends Market {
  MarketOkx({http.Client? client}) : _client = client ?? http.Client();
  static const String _baseUrl = 'https://www.okx.com';

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  @override
  Future<List<String>> getInstruments({required InstrumentType type}) async {
    final instType = _getInstType(type);
    final url = Uri.parse('$_baseUrl/api/v5/market/tickers?instType=$instType');

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch instruments: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['code'] != '0') {
      throw Exception('OKX API error: ${json['msg']}');
    }

    final data = json['data'] as List<dynamic>;
    return data.map((item) => item['instId'] as String).toList();
  }

  @override
  Future<OhlcvSeries> getKlineHistory({
    required String instrument,
    required Interval interval,
    required int limit,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final bar = _getBarInterval(interval);
    final queryParams = <String, String>{
      'instId': instrument,
      'bar': bar,
      'limit': limit.toString(),
    };

    // OKX uses 'after' for data older than timestamp (pagination forward)
    // and 'before' for data newer than timestamp (pagination backward)
    if (endTime != null) {
      queryParams['before'] = endTime.millisecondsSinceEpoch.toString();
    }
    if (startTime != null) {
      queryParams['after'] = startTime.millisecondsSinceEpoch.toString();
    }

    final url = Uri.parse('$_baseUrl/api/v5/market/candles')
        .replace(queryParameters: queryParams);

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch candles: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['code'] != '0') {
      throw Exception('OKX API error: ${json['msg']}');
    }

    final data = json['data'] as List<dynamic>;
    final ohlcvList = <Ohlcv>[];

    for (final item in data) {
      final arr = item as List<dynamic>;
      // OKX candles format: [ts, o, h, l, c, vol, volCcy, volCcyQuote, confirm]
      final open = Decimal.parse(arr[1] as String);
      final high = Decimal.parse(arr[2] as String);
      final low = Decimal.parse(arr[3] as String);
      final close = Decimal.parse(arr[4] as String);
      final volume = Decimal.parse(arr[5] as String);

      ohlcvList.add(
        Ohlcv(
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    return ohlcvList;
  }

  @override
  Set<Interval> getSupportedIntervals() {
    return {
      Interval.$1m,
      Interval.$3m,
      Interval.$5m,
      Interval.$15m,
      Interval.$30m,
      Interval.$1h,
      Interval.$2h,
      Interval.$4h,
      Interval.$6h,
      Interval.$8h,
      Interval.$12h,
      Interval.$1d,
      Interval.$2d,
      Interval.$3d,
      Interval.$1w,
      Interval.$1M,
    };
  }

  /// Convert Interval to OKX bar parameter
  String _getBarInterval(Interval interval) {
    switch (interval) {
      case Interval.$1m:
        return '1m';
      case Interval.$3m:
        return '3m';
      case Interval.$5m:
        return '5m';
      case Interval.$15m:
        return '15m';
      case Interval.$30m:
        return '30m';
      case Interval.$1h:
        return '1H';
      case Interval.$2h:
        return '2H';
      case Interval.$4h:
        return '4H';
      case Interval.$6h:
        return '6Hutc';
      case Interval.$8h:
        return '8Hutc';
      case Interval.$12h:
        return '12Hutc';
      case Interval.$1d:
        return '1Dutc';
      case Interval.$2d:
        return '2Dutc';
      case Interval.$3d:
        return '3Dutc';
      case Interval.$1w:
        return '1Wutc';
      case Interval.$1M:
        return '1Mutc';
      case _:
        throw UnsupportedError('OKX unsuport this interval: $interval');
    }
  }

  /// Convert InstrumentType to OKX instType parameter
  String _getInstType(InstrumentType type) {
    switch (type) {
      case InstrumentType.spot:
        return 'SPOT';
      case InstrumentType.perpetual:
        return 'SWAP';
      case InstrumentType.futures:
        return 'FUTURES';
      case InstrumentType.margin:
        return 'MARGIN';
      case InstrumentType.options:
        return 'OPTION';
    }
  }
}
