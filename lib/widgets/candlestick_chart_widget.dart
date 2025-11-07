import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/candlestick_data.dart';
import '../models/timeframe.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<CandlestickData> data;
  final String title;
  final Timeframe timeframe;

  const CandlestickChartWidget({
    super.key,
    required this.data,
    this.title = 'BTC/USDT',
    this.timeframe = Timeframe.h1,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  // —— 最大放大度（最小可见窗口比例）
  static const double _minXFactor = 0.1;

  // —— 单击/长按判定阈值
  static const int _longPressMs = 350; // 长按判定时长
  static const double _tapMaxMove = 8.0; // 单击允许的最大位移
  static const int _tapMaxMs = 250; // 单击允许的最长时长

  // 缩放行为（主图 / 成交量图）
  late final ZoomPanBehavior _priceZoom;
  late final ZoomPanBehavior _volZoom;

  // X 轴（必须持有轴实例，便于编程式缩放）
  late final DateTimeAxis _priceXAxis;
  late final DateTimeAxis _volXAxis;

  // ===== 主图：Y 轴（横向网格线） =====
  final NumericAxis _priceYAxis = NumericAxis(
    labelPosition: ChartDataLabelPosition.inside,
    opposedPosition: true,
    // 横向“主”网格线
    majorGridLines: MajorGridLines(
      width: 0.8,
      color: Colors.white.withValues(alpha: 0.06),
    ),
    // 横向“次”网格线
    minorGridLines: MinorGridLines(
      width: 0.5,
      color: Colors.white.withValues(alpha: 0.03),
    ),
    minorTicksPerInterval: 1, // 每个主间隔再加 1 条细线（按需调整）
    axisLine: const AxisLine(width: 0),
    labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
    numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
  );

  // 十字/轨迹
  late final TrackballBehavior _trackballBehavior;
  late final CrosshairBehavior _crosshairBehavior;

  static const double _animMs = 200.0;

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

    // 初始化 X 轴，使用 widget.timeframe 的日期格式
    _priceXAxis = DateTimeAxis(
      name: 'x',
      isVisible: false,
      majorGridLines: MajorGridLines(
        color: Colors.grey.withValues(alpha: 0.1),
        width: 1,
      ),
      axisLine: const AxisLine(width: 0),
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      dateFormat: DateFormat(widget.timeframe.dateFormat),
      intervalType: DateTimeIntervalType.auto,
    );

    _volXAxis = DateTimeAxis(
      name: 'x',
      isVisible: true,
      dateFormat: DateFormat(widget.timeframe.dateFormat),
      intervalType: DateTimeIntervalType.auto,
      majorGridLines: const MajorGridLines(width: 0),
      minorGridLines: const MinorGridLines(width: 0),
      majorTickLines: const MajorTickLines(width: 0, size: 0),
      axisLine: const AxisLine(width: 0),
    );

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

    _applyInitialViewByLastN(50);
  }

  // 计算 factor/position 并应用到两个图表
  void _applyInitialViewByLastN(int lastN) {
    if (widget.data.isEmpty) return;
    final int len = widget.data.length;
    final double factor = (lastN / len).clamp(0.0, 1.0); // 初始缩放比例
    final double position = (1.0 - factor).clamp(0.0, 1.0); // 把窗口贴到最右（最新）

    // 若你限制了最大放大度（_minXFactor），要确保初始 factor ≥ _minXFactor
    // 否则会被限制住看不到那么“窄”的窗口
    final double appliedFactor = factor.clamp(_minXFactor, 1.0);

    // 等第一帧布局完再调用（轴/行为就绪）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _priceZoom.zoomToSingleAxis(_priceXAxis, position, appliedFactor);
      _volZoom.zoomToSingleAxis(_volXAxis, position, appliedFactor);
    });
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
    // 使用 'pixel' 参数指定坐标单位为像素
    _trackballBehavior.show(p.dx, p.dy, 'pixel');
    _crosshairBehavior.show(p.dx, p.dy, 'pixel');
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

      primaryYAxis: _priceYAxis,
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
          enableSolidCandles: true, // 启用实心蜡烛
          enableTooltip: false,
          animationDuration: _animMs,
          spacing: 0.01,
          width: 0.9,
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
          spacing: 0.01,
          width: 0.9,
          animationDuration: _animMs,
        ),
      ],
    );
  }
}
