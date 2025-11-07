import 'dart:async';
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
  // 缩放行为（主图 / 成交量图）
  late final ZoomPanBehavior _priceZoom;
  late final ZoomPanBehavior _volZoom;

  // X 轴（必须持有轴实例，便于编程式缩放）
  final DateTimeAxis _priceXAxis = DateTimeAxis(
    name: 'x',
    majorGridLines: MajorGridLines(
      color: Colors.grey.withValues(alpha: 0.1),
      width: 1,
    ),
    axisLine: const AxisLine(width: 0),
    labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
    dateFormat: DateFormat('MM/dd HH:mm'),
    intervalType: DateTimeIntervalType.auto,
    // 可选：避免缩放后两图刻度不一致
    // enableAutoIntervalOnZooming: false,
  );

  final DateTimeAxis _volXAxis = DateTimeAxis(
    name: 'x',
    isVisible: false, // 底部轴不显示，但仍用于同步
    dateFormat: DateFormat('MM/dd HH:mm'),
    intervalType: DateTimeIntervalType.auto,
    // enableAutoIntervalOnZooming: false,
  );

  // 十字/轨迹
  late final TrackballBehavior _trackballBehavior;
  late final CrosshairBehavior _crosshairBehavior;

  // 递归保护（避免 A 触发 B、B 又触发 A）
  bool _syncingFromPrice = false;
  bool _syncingFromVol = false;

  // 防抖（用于 Trackball -> 信息面板）
  Timer? _debounceTimer;

  // 十字指针相关状态
  bool _isCrosshairVisible = false;
  CandlestickData? _selectedData;
  static const double _minXFactor = 0.2; // 5% 窗口

  @override
  void initState() {
    super.initState();

    // 统一定义一个“最小可见比例”（最大放大度）

    _priceZoom = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
      enableSelectionZooming: false,
      enableMouseWheelZooming: true,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: _minXFactor,
    );

    _volZoom = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
      enableSelectionZooming: false,
      enableMouseWheelZooming: true,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: _minXFactor,
    );
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.none,
      shouldAlwaysShow: false,
      lineType: TrackballLineType.none, // 不显示线，只用于定位数据点
      lineColor: Colors.transparent,
    );

    _crosshairBehavior = CrosshairBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      shouldAlwaysShow: false,
      lineType: CrosshairLineType.both, // 十字线
      lineColor: Colors.grey.withValues(alpha: 0.8),
      lineWidth: 2,
      lineDashArray: const [5, 5],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // —— 缩放同步：主图 -> 成交量图
  void _onPriceZooming(ZoomPanArgs args) {
    if (_syncingFromVol) return;
    // 只处理 X 轴事件
    if (args.axis?.name != 'x') return;

    _syncingFromPrice = true;

    // 关键：把同步过去的 factor 限制在 [_minXFactor, 1.0]
    final double factor = args.currentZoomFactor
        .clamp(_minXFactor, 1.0)
        .toDouble();

    // 将当前的缩放位置/比例同步到 Volume 图
    _volZoom.zoomToSingleAxis(_volXAxis, args.currentZoomPosition, factor);
    _syncingFromPrice = false;
  }

  // —— 缩放同步：成交量图 -> 主图
  void _onVolZooming(ZoomPanArgs args) {
    if (_syncingFromPrice) return;
    if (args.axis?.name != 'x') return;

    _syncingFromVol = true;

    final double factor = args.currentZoomFactor
        .clamp(_minXFactor, 1.0)
        .toDouble();
    _priceZoom.zoomToSingleAxis(_priceXAxis, args.currentZoomPosition, factor);
    _syncingFromVol = false;
  }

  // —— Trackball 位置变化：驱动左上角信息面板
  void _onTrackballPositionChanging(TrackballArgs args) {
    final info = args.chartPointInfo;

    int? dataPointIndex;
    try {
      dataPointIndex = info.dataPointIndex;
    } catch (_) {
      dataPointIndex = null;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (!mounted) return;

      if (dataPointIndex != null &&
          dataPointIndex >= 0 &&
          dataPointIndex < widget.data.length) {
        final newData = widget.data[dataPointIndex];
        if (!_isCrosshairVisible || newData != _selectedData) {
          setState(() {
            _isCrosshairVisible = true;
            _selectedData = newData;
          });
        }
      } else {
        if (_isCrosshairVisible) {
          setState(() {
            _isCrosshairVisible = false;
            _selectedData = null;
          });
        }
      }
    });
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
          _buildChartHeader(),

          // —— 主图（K 线）
          Expanded(
            flex: 3,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) {
                // 手指离开后延迟隐藏信息面板，避免与图表内部事件冲突
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && _isCrosshairVisible) {
                    setState(() {
                      _isCrosshairVisible = false;
                      _selectedData = null;
                    });
                  }
                });
              },
              onPointerCancel: (_) {
                if (mounted && _isCrosshairVisible) {
                  setState(() {
                    _isCrosshairVisible = false;
                    _selectedData = null;
                  });
                }
              },
              child: Stack(
                children: [
                  _buildCandlestickChart(),
                  AnimatedOpacity(
                    opacity: (_isCrosshairVisible && _selectedData != null)
                        ? 1.0
                        : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: _isCrosshairVisible && _selectedData != null
                        ? _buildCrosshairInfoPanel()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // —— 成交量图
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

      // 行为
      primaryXAxis: _priceXAxis,
      primaryYAxis: NumericAxis(
        labelPosition: ChartDataLabelPosition.inside,
        opposedPosition: true,
        majorGridLines: MajorGridLines(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        interactiveTooltip: const InteractiveTooltip(enable: true),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
      ),
      zoomPanBehavior: _priceZoom,
      trackballBehavior: _trackballBehavior,
      crosshairBehavior: _crosshairBehavior,

      // 同步回调
      onZooming: _onPriceZooming,
      onTrackballPositionChanging: _onTrackballPositionChanging,

      // Candle
      series: <CartesianSeries>[
        CandleSeries<CandlestickData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (d, _) => d.date,
          lowValueMapper: (d, _) => d.low,
          highValueMapper: (d, _) => d.high,
          openValueMapper: (d, _) => d.open,
          closeValueMapper: (d, _) => d.close,
          bearColor: const Color(0xFFEF5350),
          bullColor: const Color(0xFF26A69A),
          enableTooltip: false,
          animationDuration: 800,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: false),
    );
  }

  Widget _buildVolumeChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),

      primaryXAxis: _volXAxis,
      primaryYAxis: NumericAxis(
        isVisible: false,
        opposedPosition: true,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        numberFormat: NumberFormat.compact(),
      ),

      zoomPanBehavior: _volZoom,
      onZooming: _onVolZooming,

      series: <CartesianSeries>[
        ColumnSeries<CandlestickData, DateTime>(
          dataSource: widget.data,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.volume,
          pointColorMapper: (d, _) => d.isBullish
              ? const Color(0xFF26A69A).withValues(alpha: 0.5)
              : const Color(0xFFEF5350).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
          spacing: 0.1,
        ),
      ],
    );
  }

  // —— 左上角信息面板
  Widget _buildCrosshairInfoPanel() {
    if (_selectedData == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MM/dd HH:mm');
    final isPositive = _selectedData!.close >= _selectedData!.open;
    final change = _selectedData!.close - _selectedData!.open;
    final changePercent = (change / _selectedData!.open) * 100;

    return Positioned(
      top: 6,
      left: 6,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateFormat.format(_selectedData!.date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              _buildInfoRow('O', _selectedData!.open, Colors.grey),
              _buildInfoRow('H', _selectedData!.high, Colors.green),
              _buildInfoRow('L', _selectedData!.low, Colors.red),
              _buildInfoRow(
                'C',
                _selectedData!.close,
                isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 2),
              Container(
                height: 0.5,
                width: 80,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 2),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: Colors.grey, fontSize: 8),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
