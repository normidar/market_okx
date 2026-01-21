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
    // Determine if we're fetching historical data or recent data
    final isHistoricalData = _isHistoricalData(endTime, interval);

    // Validate limit according to OKX API constraints
    // Only apply 1440 limit for recent data
    // Historical data endpoint (/api/v5/market/history-candles) has no such limit
    if (!isHistoricalData && limit > 1440) {
      throw ArgumentError(
        'Limit must be 1440 or less for recent data. Requested: $limit',
      );
    }

    final bar = _getBarInterval(interval);

    // If limit <= 300, make a single request
    if (limit <= 300) {
      final result = await _fetchCandlesWithTimestamp(
        instrument: instrument,
        bar: bar,
        limit: limit,
        interval: interval,
        startTime: startTime,
        endTime: endTime,
      );
      return result.ohlcvList;
    }

    // If limit > 300, make multiple requests with pagination
    final allOhlcv = <Ohlcv>[];
    var remaining = limit;
    var currentBefore = endTime?.millisecondsSinceEpoch.toString();

    while (remaining > 0) {
      final batchLimit = remaining > 300 ? 300 : remaining;

      final result = await _fetchCandlesWithTimestamp(
        instrument: instrument,
        bar: bar,
        limit: batchLimit,
        interval: interval,
        startTime: startTime,
        endTime: currentBefore != null
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(currentBefore))
            : null,
      );

      if (result.ohlcvList.isEmpty) {
        break; // No more data available
      }

      allOhlcv.addAll(result.ohlcvList);
      remaining -= result.ohlcvList.length;

      // If we got less data than requested, no more data is available
      if (result.ohlcvList.length < batchLimit) {
        break;
      }

      // Update the 'before' parameter with the oldest timestamp from this batch
      // OKX returns data in descending order (newest first)
      // The last element has the oldest timestamp
      // We need to subtract 1ms to avoid getting the same timestamp again
      if (result.oldestTimestamp != null) {
        final oldestMs = int.parse(result.oldestTimestamp!);
        currentBefore = (oldestMs - 1).toString();
      } else {
        break; // No timestamp available, stop pagination
      }
    }

    return allOhlcv;
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

  /// Fetch candles from OKX API with timestamp tracking
  Future<({List<Ohlcv> ohlcvList, String? oldestTimestamp})>
      _fetchCandlesWithTimestamp({
    required String instrument,
    required String bar,
    required int limit,
    required Interval interval,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
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

    // Automatically choose the appropriate endpoint based on the data being requested
    // - history-candles: for historical data (no 1440 limit)
    // - candles: for recent data (1440 limit applies)
    final useHistoryEndpoint = _isHistoricalData(endTime, interval);
    final endpoint = useHistoryEndpoint
        ? '/api/v5/market/history-candles'
        : '/api/v5/market/candles';
    final url =
        Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);

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
    String? oldestTimestamp;

    for (final item in data) {
      final arr = item as List<dynamic>;
      // OKX candles format: [ts, o, h, l, c, vol, volCcy, volCcyQuote, confirm]
      final timestamp = arr[0] as String;
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

      // Keep track of the oldest (last) timestamp for pagination
      oldestTimestamp = timestamp;
    }

    return (ohlcvList: ohlcvList, oldestTimestamp: oldestTimestamp);
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

  /// Determine if we should use the history-candles endpoint
  ///
  /// Returns true if the data being requested is historical (not recent).
  /// Historical data uses the history-candles endpoint which has no 1440 limit.
  bool _isHistoricalData(DateTime? endTime, Interval interval) {
    if (endTime == null) {
      return false; // No endTime means fetching recent data
    }

    // If endTime is more than 1 hour in the past, consider it historical
    // This threshold can be adjusted based on your needs
    final now = DateTime.now();
    final threshold = now.subtract(interval.duration * 3);

    return endTime.isBefore(threshold);
  }
}
