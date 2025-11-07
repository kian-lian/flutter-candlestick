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
  // —— 最大放大度（最小可见窗口比例）
  static const double _minXFactor = 0.2;

  // —— 单击/长按判定阈值
  static const int _longPressMs = 350; // 长按判定时长
  static const double _tapMaxMove = 8.0; // 单击允许的最大位移
  static const int _tapMaxMs = 250; // 单击允许的最长时长

  // 缩放行为（主图 / 成交量图）
  late final ZoomPanBehavior _priceZoom;
  late final ZoomPanBehavior _volZoom;

  // X 轴（必须持有轴实例，便于编程式缩放）
  final DateTimeAxis _priceXAxis = DateTimeAxis(
    name: 'x',
    majorGridLines: MajorGridLines(
      color: Colors.grey /*.withOpacity(0.1)*/ .withValues(alpha: 0.1),
      width: 1,
    ),
    axisLine: const AxisLine(width: 0),
    labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
    dateFormat: DateFormat('MM/dd HH:mm'),
    intervalType: DateTimeIntervalType.auto,
  );

  final DateTimeAxis _volXAxis = DateTimeAxis(
    name: 'x',
    isVisible: false,
    dateFormat: DateFormat('MM/dd HH:mm'),
    intervalType: DateTimeIntervalType.auto,
  );

  // 十字/轨迹
  late final TrackballBehavior _trackballBehavior;
  late final CrosshairBehavior _crosshairBehavior;

  // 递归保护（避免 A 触发 B、B 又触发 A）
  bool _syncingFromPrice = false;
  bool _syncingFromVol = false;

  // —— 手势状态
  bool _isPinned = false; // 当前是否固定/显示
  bool _isPointerDown = false; // 手指是否按下
  bool _longPressActive = false; // 是否已进入长按跟随模式
  Offset? _downPos;
  DateTime? _downAt;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();

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

    // —— Trackball 只作为“十字旁的小面板”，不自动触发，全部由代码控制
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.none, // 重要：不要自动触发
      shouldAlwaysShow: true, // 显示后不自动消失
      lineType: TrackballLineType.none, // 十字线由 crosshair 绘制
      tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Color(0xFF1E1E1E),
        borderColor: Colors.grey,
        borderWidth: 0.5,
        textStyle: TextStyle(color: Colors.white, fontSize: 10),
      ),
      // 如需自定义面板内容，可在这里加 builder:
      // builder: (ctx, details) => ...
    );

    // —— Crosshair 只画线，不自动触发
    _crosshairBehavior = CrosshairBehavior(
      enable: true,
      activationMode: ActivationMode.none, // 重要：不要自动触发
      shouldAlwaysShow: true, // 显示后不自动消失
      lineType: CrosshairLineType.both,
      lineColor: Colors.grey.withValues(alpha: 0.8),
      lineWidth: 2,
      lineDashArray: const [5, 5],
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  // —— 缩放同步：主图 -> 成交量图（带“最大放大度”夹紧）
  void _onPriceZooming(ZoomPanArgs args) {
    if (_syncingFromVol) return;
    if (args.axis?.name != 'x') return;
    _syncingFromPrice = true;
    final factor = args.currentZoomFactor.clamp(_minXFactor, 1.0).toDouble();
    _volZoom.zoomToSingleAxis(_volXAxis, args.currentZoomPosition, factor);
    _syncingFromPrice = false;
  }

  // —— 缩放同步：成交量图 -> 主图（带“最大放大度”夹紧）
  void _onVolZooming(ZoomPanArgs args) {
    if (_syncingFromPrice) return;
    if (args.axis?.name != 'x') return;
    _syncingFromVol = true;
    final factor = args.currentZoomFactor.clamp(_minXFactor, 1.0).toDouble();
    _priceZoom.zoomToSingleAxis(_priceXAxis, args.currentZoomPosition, factor);
    _syncingFromVol = false;
  }

  // —— 程序化显示/隐藏（在像素坐标处）
  void _showAt(Offset p) {
    _trackballBehavior.show(p.dx, p.dy);
    _crosshairBehavior.show(p.dx, p.dy);
    _isPinned = true;
  }

  void _hideAll() {
    _trackballBehavior.hide();
    _crosshairBehavior.hide();
    _isPinned = false;
  }

  // —— 手势：按下/移动/抬起/取消
  void _onDown(ChartTouchInteractionArgs args) {
    _isPointerDown = true;
    _longPressActive = false;
    _downPos = args.position;
    _downAt = DateTime.now();

    // 启动长按定时器：到时未移动过远则进入长按模式并显示
    _longPressTimer?.cancel();
    _longPressTimer = Timer(Duration(milliseconds: _longPressMs), () {
      if (!_isPointerDown || _downPos == null) return;
      // 长按触发
      _longPressActive = true;
      _showAt(_downPos!);
    });
  }

  void _onMove(ChartTouchInteractionArgs args) {
    if (!_isPointerDown) return;
    // 如果进入了长按模式，跟随移动
    if (_longPressActive) {
      _showAt(args.position);
    } else {
      // 未进入长按：若移动过远，取消长按判定
      if (_downPos != null &&
          (args.position - _downPos!).distance > _tapMaxMove) {
        _longPressTimer?.cancel();
      }
    }
  }

  void _onUp(ChartTouchInteractionArgs args) {
    // 结束按压
    _longPressTimer?.cancel();

    final wasLong = _longPressActive;
    final pressDurationMs = _downAt == null
        ? 9999
        : DateTime.now().difference(_downAt!).inMilliseconds;
    final movedFar = _downPos == null
        ? true
        : (args.position - _downPos!).distance > _tapMaxMove;
    final isTap = !wasLong && !movedFar && pressDurationMs <= _tapMaxMs;

    if (wasLong) {
      // 长按松开：保持当前显示（固定）
      _isPinned = true;
    } else if (isTap) {
      // 单击：切换显示/隐藏
      if (_isPinned) {
        _hideAll();
      } else {
        _showAt(args.position);
      }
    }
    _isPointerDown = false;
    _longPressActive = false;
    _downPos = null;
    _downAt = null;
  }

  void _onCancel(ChartTouchInteractionArgs args) {
    _longPressTimer?.cancel();
    _isPointerDown = false;
    _longPressActive = false;
    _downPos = null;
    _downAt = null;
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
          Expanded(flex: 3, child: _buildCandlestickChart()),
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
        ],
      ),
    );
  }

  Widget _buildCandlestickChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),

      // —— 我们用这些回调实现“单击固定/再次单击隐藏；长按跟随，松开固定”
      onChartTouchInteractionDown: _onDown,
      onChartTouchInteractionMove: _onMove,
      onChartTouchInteractionUp: _onUp,
      // onChartTouchInteractionCancel: _onCancel,

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
      primaryYAxis: const NumericAxis(
        isVisible: false,
        opposedPosition: true,
        majorGridLines: MajorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
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
}
