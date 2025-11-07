import 'dart:math';
import '../models/candlestick_data.dart';
import '../models/timeframe.dart';

class SampleDataProvider {
  static final Random _random = Random();

  /// Generates realistic candlestick data for demo purposes
  /// Similar to what you'd see on OKX or Bitget
  static List<CandlestickData> generateCandlestickData({
    int count = 100,
    double startPrice = 45000.0,
    Duration interval = const Duration(hours: 1),
  }) {
    final data = <CandlestickData>[];
    DateTime currentTime = DateTime.now().subtract(interval * count);
    double currentPrice = startPrice;

    for (int i = 0; i < count; i++) {
      // Generate realistic price movement
      final volatility = currentPrice * 0.02; // 2% volatility
      final trend = (_random.nextDouble() - 0.5) * volatility;

      // Generate OHLC values
      final open = currentPrice;
      final close = currentPrice + trend;

      // High and low based on the trend
      final range = volatility * 0.5;
      final high = max(open, close) + _random.nextDouble() * range;
      final low = min(open, close) - _random.nextDouble() * range;

      // Generate volume (higher volume on larger price movements)
      final priceChange = (close - open).abs();
      final baseVolume = 1000000.0;
      final volumeMultiplier = 1.0 + (priceChange / currentPrice) * 10;
      final volume = baseVolume * volumeMultiplier * (0.5 + _random.nextDouble());

      data.add(CandlestickData(
        date: currentTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));

      currentTime = currentTime.add(interval);
      currentPrice = close;
    }

    return data;
  }

  /// Generates Bitcoin-like candlestick data
  static List<CandlestickData> generateBitcoinData({
    int? count,
    Timeframe timeframe = Timeframe.h1,
  }) {
    return generateCandlestickData(
      count: count ?? timeframe.defaultDataCount,
      startPrice: 45000 + _random.nextDouble() * 5000, // BTC price range
      interval: timeframe.duration,
    );
  }

  /// Generates Ethereum-like candlestick data
  static List<CandlestickData> generateEthereumData({
    int? count,
    Timeframe timeframe = Timeframe.h1,
  }) {
    return generateCandlestickData(
      count: count ?? timeframe.defaultDataCount,
      startPrice: 2500 + _random.nextDouble() * 500, // ETH price range
      interval: timeframe.duration,
    );
  }

  /// Generates trending upward data
  static List<CandlestickData> generateBullishData({
    int? count,
    double startPrice = 45000.0,
    Timeframe timeframe = Timeframe.h1,
  }) {
    final data = <CandlestickData>[];
    final dataCount = count ?? timeframe.defaultDataCount;
    DateTime currentTime = DateTime.now().subtract(timeframe.duration * dataCount);
    double currentPrice = startPrice;

    for (int i = 0; i < dataCount; i++) {
      final volatility = currentPrice * 0.015;
      // Add bullish bias
      final trend = (_random.nextDouble() - 0.3) * volatility;

      final open = currentPrice;
      final close = currentPrice + trend;

      final range = volatility * 0.4;
      final high = max(open, close) + _random.nextDouble() * range;
      final low = min(open, close) - _random.nextDouble() * range * 0.5;

      final baseVolume = 1000000.0;
      final volume = baseVolume * (0.5 + _random.nextDouble() * 1.5);

      data.add(CandlestickData(
        date: currentTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));

      currentTime = currentTime.add(timeframe.duration);
      currentPrice = close;
    }

    return data;
  }

  /// Generates trending downward data
  static List<CandlestickData> generateBearishData({
    int? count,
    double startPrice = 45000.0,
    Timeframe timeframe = Timeframe.h1,
  }) {
    final data = <CandlestickData>[];
    final dataCount = count ?? timeframe.defaultDataCount;
    DateTime currentTime = DateTime.now().subtract(timeframe.duration * dataCount);
    double currentPrice = startPrice;

    for (int i = 0; i < dataCount; i++) {
      final volatility = currentPrice * 0.015;
      // Add bearish bias
      final trend = (_random.nextDouble() - 0.7) * volatility;

      final open = currentPrice;
      final close = currentPrice + trend;

      final range = volatility * 0.4;
      final high = max(open, close) + _random.nextDouble() * range * 0.5;
      final low = min(open, close) - _random.nextDouble() * range;

      final baseVolume = 1000000.0;
      final volume = baseVolume * (0.5 + _random.nextDouble() * 1.5);

      data.add(CandlestickData(
        date: currentTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));

      currentTime = currentTime.add(timeframe.duration);
      currentPrice = close;
    }

    return data;
  }

  /// Generates sideways/ranging market data
  static List<CandlestickData> generateRangingData({
    int? count,
    double startPrice = 45000.0,
    double rangePercent = 0.05, // 5% range
    Timeframe timeframe = Timeframe.h1,
  }) {
    final data = <CandlestickData>[];
    final dataCount = count ?? timeframe.defaultDataCount;
    DateTime currentTime = DateTime.now().subtract(timeframe.duration * dataCount);
    final centerPrice = startPrice;
    final maxRange = startPrice * rangePercent;

    for (int i = 0; i < dataCount; i++) {
      // Keep price within range
      final currentPrice = centerPrice + (_random.nextDouble() - 0.5) * maxRange * 2;
      final volatility = currentPrice * 0.01;
      final trend = (_random.nextDouble() - 0.5) * volatility;

      final open = currentPrice;
      final close = currentPrice + trend;

      final range = volatility * 0.3;
      final high = max(open, close) + _random.nextDouble() * range;
      final low = min(open, close) - _random.nextDouble() * range;

      final baseVolume = 800000.0;
      final volume = baseVolume * (0.5 + _random.nextDouble());

      data.add(CandlestickData(
        date: currentTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));

      currentTime = currentTime.add(timeframe.duration);
    }

    return data;
  }
}
