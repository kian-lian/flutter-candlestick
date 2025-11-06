import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/candlestick_data.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<CandlestickData> data;
  final String title;

  const CandlestickChartWidget({
    super.key,
    required this.data,
    this.title = 'BTC/USDT',
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;
  late CrosshairBehavior _crosshairBehavior;

  @override
  void initState() {
    super.initState();

    // Configure zoom and pan behavior
    // 禁用 enableSelectionZooming 避免长按时选中放大
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
      enableSelectionZooming: false, // 禁用选中放大，避免与十字指针冲突
      enableMouseWheelZooming: true,
      zoomMode: ZoomMode.x,
    );

    // 禁用 trackball，改用 crosshair
    _trackballBehavior = TrackballBehavior(enable: false);

    // 配置十字指针 - 长按激活，可以滑动移动指针
    _crosshairBehavior = CrosshairBehavior(
      enable: true,
      activationMode: ActivationMode.longPress, // 长按激活
      shouldAlwaysShow: false,
      lineType: CrosshairLineType.both, // 显示水平和垂直十字线
      lineColor: Colors.grey.withValues(alpha: 0.6),
      lineWidth: 1,
      lineDashArray: const [5, 5],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Chart Header
          _buildChartHeader(),

          // Main Chart
          Expanded(
            flex: 3,
            child: GestureDetector(
              onHorizontalDragStart: (details) => {},
              child: _buildCandlestickChart(),
            ),
          ),

          // Volume Chart
          Expanded(flex: 1, child: _buildVolumeChart()),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final latestData = widget.data.last;
    final priceChange = latestData.close - widget.data.first.close;
    final priceChangePercent = (priceChange / widget.data.first.close) * 100;
    final isPositive = priceChange >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '\$${latestData.close.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${priceChangePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatItem('H', latestData.high, Colors.green),
              const SizedBox(width: 16),
              _buildStatItem('L', latestData.low, Colors.red),
              const SizedBox(width: 16),
              _buildStatItem('O', latestData.open, Colors.grey),
              const SizedBox(width: 16),
              _buildStatItem('C', latestData.close, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCandlestickChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),

      // Enable zoom and pan
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      crosshairBehavior: _crosshairBehavior,

      // Primary X Axis (DateTime)
      primaryXAxis: DateTimeAxis(
        majorGridLines: MajorGridLines(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        dateFormat: DateFormat('MM/dd HH:mm'),
        intervalType: DateTimeIntervalType.auto,
      ),

      // Primary Y Axis (Price)
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: MajorGridLines(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
      ),

      // Candlestick Series
      series: <CartesianSeries>[
        CandleSeries<CandlestickData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (CandlestickData data, _) => data.date,
          lowValueMapper: (CandlestickData data, _) => data.low,
          highValueMapper: (CandlestickData data, _) => data.high,
          openValueMapper: (CandlestickData data, _) => data.open,
          closeValueMapper: (CandlestickData data, _) => data.close,

          // Styling
          bearColor: const Color(0xFFEF5350), // Red for bearish
          bullColor: const Color(0xFF26A69A), // Green for bullish
          // Enable tooltip
          enableTooltip: true,

          // Smooth rendering
          animationDuration: 1000,
        ),
      ],

      // Tooltip behavior - activated on tap
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        format:
            'Date: point.x\nO: point.open\nH: point.high\nL: point.low\nC: point.close',
        color: const Color(0xFF1E1E1E),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
        borderColor: Colors.grey,
        borderWidth: 1,
      ),
    );
  }

  Widget _buildVolumeChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),

      // Primary X Axis (DateTime)
      primaryXAxis: DateTimeAxis(isVisible: false),

      // Primary Y Axis (Volume)
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        numberFormat: NumberFormat.compact(),
      ),

      // Volume Series
      series: <CartesianSeries>[
        ColumnSeries<CandlestickData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (CandlestickData data, _) => data.date,
          yValueMapper: (CandlestickData data, _) => data.volume,

          // Color based on bullish/bearish
          pointColorMapper: (CandlestickData data, _) => data.isBullish
              ? const Color(0xFF26A69A).withValues(alpha: 0.5)
              : const Color(0xFFEF5350).withValues(alpha: 0.5),

          borderRadius: BorderRadius.circular(2),
          spacing: 0.1,
        ),
      ],
    );
  }
}
