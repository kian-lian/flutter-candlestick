class CandlestickData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandlestickData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  // Helper to check if candle is bullish (green)
  bool get isBullish => close >= open;

  // Helper to check if candle is bearish (red)
  bool get isBearish => close < open;
}