# Candlestick 蜡烛图实现详解

## 目录

1. [项目概述](#1-项目概述)
2. [技术栈](#2-技术栈)
3. [项目架构](#3-项目架构)
4. [核心数据模型](#4-核心数据模型)
5. [数据生成器](#5-数据生成器)
6. [蜡烛图组件实现](#6-蜡烛图组件实现)
7. [交互功能实现](#7-交互功能实现)
8. [UI设计与样式](#8-ui设计与样式)
9. [关键技术难点](#9-关键技术难点)
10. [扩展与优化建议](#10-扩展与优化建议)

---

## 1. 项目概述

本项目是一个基于 **Flutter** 的加密货币交易蜡烛图（K线图）应用，使用 **Syncfusion Flutter Charts** 库实现专业级的图表展示。该应用模拟了类似 OKX、Bitget 等加密货币交易所的图表功能，支持多种市场趋势展示、实时交互和专业的技术分析工具。

### 主要功能

- ✅ 实时蜡烛图展示（OHLC数据）
- ✅ 成交量柱状图
- ✅ 多种市场趋势（牛市、中性、熊市）
- ✅ 多时间周期切换（1H、4H、1D、1W）
- ✅ 缩放和平移操作
- ✅ 十字光标和实时数据面板
- ✅ 深色主题UI

---

## 2. 技术栈

### 核心技术

| 技术/库 | 版本 | 用途 |
|--------|------|------|
| Flutter | SDK ^3.9.0 | 跨平台UI框架 |
| Dart | ^3.9.0 | 编程语言 |
| syncfusion_flutter_charts | ^28.1.33 | 专业图表库 |
| intl | ^0.19.0 | 国际化和日期格式化 |

### 项目依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  syncfusion_flutter_charts: ^28.1.33
  intl: ^0.19.0
```

---

## 3. 项目架构

### 目录结构

```
lib/
├── main.dart                              # 应用入口和主页面
├── models/                                # 数据模型层
│   └── candlestick_data.dart             # 蜡烛图数据模型
├── data/                                  # 数据层
│   └── sample_data_provider.dart         # 样本数据生成器
└── widgets/                               # UI组件层
    └── candlestick_chart_widget.dart     # 蜡烛图组件
```

### 架构设计原则

1. **分层架构**：将数据模型、数据提供和UI展示分离
2. **组件化**：每个功能独立封装为可复用组件
3. **状态管理**：使用 StatefulWidget 管理局部状态
4. **关注点分离**：数据生成、图表渲染、用户交互各自独立

---

## 4. 核心数据模型

### CandlestickData 模型

`lib/models/candlestick_data.dart`

```dart
class CandlestickData {
  final DateTime date;      // 时间戳
  final double open;         // 开盘价
  final double high;         // 最高价
  final double low;          // 最低价
  final double close;        // 收盘价
  final double volume;       // 成交量

  CandlestickData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  // 辅助属性：判断是否为阳线（绿色/涨）
  bool get isBullish => close >= open;

  // 辅助属性：判断是否为阴线（红色/跌）
  bool get isBearish => close < open;
}
```

### 数据结构说明

这是标准的 **OHLC** (Open-High-Low-Close) 数据结构，每个数据点代表一个时间周期内的价格变化：

- **date**: 时间周期的起始时间
- **open**: 该周期的第一笔交易价格
- **high**: 该周期内的最高价格
- **low**: 该周期内的最低价格
- **close**: 该周期的最后一笔交易价格
- **volume**: 该周期的总成交量

---

## 5. 数据生成器

### SampleDataProvider 类

`lib/data/sample_data_provider.dart`

该类负责生成模拟的交易数据，支持多种市场趋势模式。

#### 核心算法：生成蜡烛图数据

```dart
static List<CandlestickData> generateCandlestickData({
  int count = 100,
  double startPrice = 45000.0,
  Duration interval = const Duration(hours: 1),
}) {
  final data = <CandlestickData>[];
  DateTime currentTime = DateTime.now().subtract(interval * count);
  double currentPrice = startPrice;

  for (int i = 0; i < count; i++) {
    // 1. 生成价格波动
    final volatility = currentPrice * 0.02;  // 2% 波动率
    final trend = (_random.nextDouble() - 0.5) * volatility;

    // 2. 计算 OHLC 值
    final open = currentPrice;
    final close = currentPrice + trend;
    
    final range = volatility * 0.5;
    final high = max(open, close) + _random.nextDouble() * range;
    final low = min(open, close) - _random.nextDouble() * range;

    // 3. 生成成交量（价格波动大时成交量也大）
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
```

#### 数据生成策略

##### 1. 牛市数据（Bullish）

```dart
static List<CandlestickData> generateBullishData({
  int count = 100,
  double startPrice = 45000.0,
}) {
  // 添加上涨偏向：trend = (_random.nextDouble() - 0.3) * volatility
  // 0.3 < 0.5，使得生成的随机数更偏向正值
}
```

**特点**：
- 收盘价倾向于高于开盘价
- 整体趋势向上
- 上影线更长

##### 2. 熊市数据（Bearish）

```dart
static List<CandlestickData> generateBearishData({
  int count = 100,
  double startPrice = 45000.0,
}) {
  // 添加下跌偏向：trend = (_random.nextDouble() - 0.7) * volatility
  // 0.7 > 0.5，使得生成的随机数更偏向负值
}
```

**特点**：
- 收盘价倾向于低于开盘价
- 整体趋势向下
- 下影线更长

##### 3. 横盘数据（Ranging）

```dart
static List<CandlestickData> generateRangingData({
  int count = 100,
  double startPrice = 45000.0,
  double rangePercent = 0.05,  // 5% 区间
}) {
  // 价格在中心价格上下波动
  final currentPrice = centerPrice + (_random.nextDouble() - 0.5) * maxRange * 2;
}
```

**特点**：
- 价格在固定区间内波动
- 无明显趋势方向
- 波动幅度可控

---

## 6. 蜡烛图组件实现

### CandlestickChartWidget 组件

`lib/widgets/candlestick_chart_widget.dart`

这是核心的图表展示组件，使用 Syncfusion 的 `SfCartesianChart` 实现。

#### 组件结构

```dart
class CandlestickChartWidget extends StatefulWidget {
  final List<CandlestickData> data;  // 数据源
  final String title;                 // 标题（如 BTC/USDT）
}
```

#### 核心功能实现

##### 1. 图表行为配置

```dart
@override
void initState() {
  super.initState();

  // 缩放和平移配置
  _zoomPanBehavior = ZoomPanBehavior(
    enablePinching: true,           // 双指缩放
    enableDoubleTapZooming: true,   // 双击缩放
    enablePanning: true,            // 平移
    enableSelectionZooming: false,  // 禁用选中缩放（避免与十字线冲突）
    enableMouseWheelZooming: true,  // 鼠标滚轮缩放
    zoomMode: ZoomMode.x,           // 仅横向缩放
  );

  // 轨迹球配置（用于数据点定位）
  _trackballBehavior = TrackballBehavior(
    enable: true,
    activationMode: ActivationMode.longPress,  // 长按激活
    tooltipDisplayMode: TrackballDisplayMode.none,
    lineType: TrackballLineType.none,          // 不显示线
  );

  // 十字线配置
  _crosshairBehavior = CrosshairBehavior(
    enable: true,
    activationMode: ActivationMode.longPress,
    lineType: CrosshairLineType.both,          // 横竖十字线
    lineColor: Colors.grey.withValues(alpha: 0.8),
    lineWidth: 2,
    lineDashArray: const [5, 5],               // 虚线
  );
}
```

##### 2. 主蜡烛图实现

```dart
Widget _buildCandlestickChart() {
  return SfCartesianChart(
    backgroundColor: Colors.transparent,
    plotAreaBorderWidth: 0,
    
    // 应用交互行为
    zoomPanBehavior: _zoomPanBehavior,
    trackballBehavior: _trackballBehavior,
    crosshairBehavior: _crosshairBehavior,
    onTrackballPositionChanging: _onTrackballPositionChanging,

    // X轴：时间轴
    primaryXAxis: DateTimeAxis(
      majorGridLines: MajorGridLines(
        color: Colors.grey.withValues(alpha: 0.1),
        width: 1,
      ),
      dateFormat: DateFormat('MM/dd HH:mm'),
      intervalType: DateTimeIntervalType.auto,
    ),

    // Y轴：价格轴（右侧）
    primaryYAxis: NumericAxis(
      opposedPosition: true,  // 显示在右侧
      numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
    ),

    // 蜡烛图系列
    series: <CartesianSeries>[
      CandleSeries<CandlestickData, DateTime>(
        dataSource: widget.data,
        xValueMapper: (CandlestickData data, _) => data.date,
        lowValueMapper: (CandlestickData data, _) => data.low,
        highValueMapper: (CandlestickData data, _) => data.high,
        openValueMapper: (CandlestickData data, _) => data.open,
        closeValueMapper: (CandlestickData data, _) => data.close,
        
        // 颜色配置
        bearColor: const Color(0xFFEF5350),  // 阴线：红色
        bullColor: const Color(0xFF26A69A),  // 阳线：绿色
        
        enableTooltip: false,
        animationDuration: 1000,
      ),
    ],
  );
}
```

##### 3. 成交量图实现

```dart
Widget _buildVolumeChart() {
  return SfCartesianChart(
    backgroundColor: Colors.transparent,
    
    // X轴：隐藏（与主图共享）
    primaryXAxis: DateTimeAxis(isVisible: false),
    
    // Y轴：成交量（右侧）
    primaryYAxis: NumericAxis(
      opposedPosition: true,
      numberFormat: NumberFormat.compact(),  // 简化数字显示（如 1.2M）
    ),

    // 柱状图系列
    series: <CartesianSeries>[
      ColumnSeries<CandlestickData, DateTime>(
        dataSource: widget.data,
        xValueMapper: (CandlestickData data, _) => data.date,
        yValueMapper: (CandlestickData data, _) => data.volume,
        
        // 根据涨跌着色
        pointColorMapper: (CandlestickData data, _) => data.isBullish
            ? const Color(0xFF26A69A).withValues(alpha: 0.5)
            : const Color(0xFFEF5350).withValues(alpha: 0.5),
        
        borderRadius: BorderRadius.circular(2),
        spacing: 0.1,
      ),
    ],
  );
}
```

---

## 7. 交互功能实现

### 十字光标 + 数据面板

这是整个项目中最复杂的交互功能实现。

#### 实现思路

1. **Trackball** 用于捕获用户长按位置，定位到最近的数据点
2. **Crosshair** 显示十字线
3. **自定义信息面板** 显示选中数据点的详细信息

#### 核心代码

```dart
// 防抖定时器，减少频繁更新
Timer? _debounceTimer;

void _onTrackballPositionChanging(TrackballArgs args) {
  final chartPointInfo = args.chartPointInfo;
  
  // 获取数据点索引
  int? dataPointIndex;
  try {
    dataPointIndex = chartPointInfo.dataPointIndex;
  } catch (e) {
    dataPointIndex = null;
  }

  // 防抖处理
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 16), () {
    if (!mounted) return;

    if (dataPointIndex != null && 
        dataPointIndex >= 0 && 
        dataPointIndex < widget.data.length) {
      // 激活十字线和数据面板
      final newData = widget.data[dataPointIndex];
      
      if (!_isCrosshairVisible || newData != _selectedData) {
        setState(() {
          _isCrosshairVisible = true;
          _selectedData = newData;
        });
      }
    } else {
      // 隐藏十字线和数据面板
      if (_isCrosshairVisible) {
        setState(() {
          _isCrosshairVisible = false;
          _selectedData = null;
        });
      }
    }
  });
}
```

#### 信息面板实现

```dart
Widget _buildCrosshairInfoPanel() {
  if (_selectedData == null) return const SizedBox.shrink();

  final dateFormat = DateFormat('MM/dd HH:mm');
  final isPositive = _selectedData!.close >= _selectedData!.open;
  final change = _selectedData!.close - _selectedData!.open;
  final changePercent = (change / _selectedData!.open) * 100;

  return Positioned(
    top: 6,
    left: 6,
    child: IgnorePointer(  // 不阻挡用户交互
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [...],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间
            Text(dateFormat.format(_selectedData!.date)),
            
            // OHLC 数据
            _buildInfoRow('O', _selectedData!.open, Colors.grey),
            _buildInfoRow('H', _selectedData!.high, Colors.green),
            _buildInfoRow('L', _selectedData!.low, Colors.red),
            _buildInfoRow('C', _selectedData!.close, 
                isPositive ? Colors.green : Colors.red),
            
            // 涨跌幅
            Text('${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%'),
          ],
        ),
      ),
    ),
  );
}
```

#### 动画效果

```dart
// 在主图上层叠加信息面板，带淡入淡出动画
Stack(
  children: [
    _buildCandlestickChart(),
    AnimatedOpacity(
      opacity: (_isCrosshairVisible && _selectedData != null) ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: _isCrosshairVisible && _selectedData != null
          ? _buildCrosshairInfoPanel()
          : const SizedBox.shrink(),
    ),
  ],
)
```

### 防抖机制（Debounce）

为了避免频繁的 `setState` 调用导致性能问题和闪烁，实现了防抖机制：

```dart
Timer? _debounceTimer;

void _onTrackballPositionChanging(TrackballArgs args) {
  _debounceTimer?.cancel();  // 取消之前的定时器
  
  // 延迟 16ms（约一帧）后执行
  _debounceTimer = Timer(const Duration(milliseconds: 16), () {
    // 更新状态
  });
}

@override
void dispose() {
  _debounceTimer?.cancel();  // 组件销毁时清理
  super.dispose();
}
```

---

## 8. UI设计与样式

### 主题配置

#### 应用级主题

```dart
MaterialApp(
  theme: ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),  // 深黑背景
    primaryColor: const Color(0xFF26A69A),              // 青绿主色
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
    ),
  ),
)
```

#### 颜色方案

| 用途 | 颜色代码 | 说明 |
|------|---------|------|
| 背景色 | `0xFF0D0D0D` | 深黑色，护眼 |
| 卡片背景 | `0xFF1A1A1A` | 浅黑色 |
| 阳线/涨 | `0xFF26A69A` | 青绿色（交易所标准） |
| 阴线/跌 | `0xFFEF5350` | 柔和红色 |
| 文字主色 | `Colors.white` | 白色 |
| 文字次色 | `Colors.grey` | 灰色 |

### 图表头部信息

```dart
Widget _buildChartHeader() {
  final latestData = widget.data.last;
  final priceChange = latestData.close - widget.data.first.close;
  final priceChangePercent = (priceChange / widget.data.first.close) * 100;
  final isPositive = priceChange >= 0;

  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 交易对名称
        Text(widget.title, style: ...),
        
        // 最新价格
        Text('\$${latestData.close.toStringAsFixed(2)}', style: ...),
        
        // 涨跌幅标签
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // OHLC 统计信息
        Row(
          children: [
            _buildStatItem('H', latestData.high, Colors.green),
            _buildStatItem('L', latestData.low, Colors.red),
            _buildStatItem('O', latestData.open, Colors.grey),
            _buildStatItem('C', latestData.close, Colors.grey),
          ],
        ),
      ],
    ),
  );
}
```

### 时间周期选择器

使用 `ChoiceChip` 实现：

```dart
Row(
  children: List.generate(_timeframes.length, (index) {
    final isSelected = _selectedTimeframe == index;
    return ChoiceChip(
      label: Text(_timeframes[index]),  // '1H', '4H', '1D', '1W'
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTimeframe = index;
        });
      },
      selectedColor: const Color(0xFF26A69A),
      backgroundColor: const Color(0xFF2A2A2A),
    );
  }),
)
```

---

## 9. 关键技术难点

### 难点1：Trackball 与 Crosshair 的联动

**问题**：Syncfusion 的 Trackball 和 Crosshair 是两个独立的行为，需要让它们同步工作。

**解决方案**：
- 使用 Trackball 的 `onTrackballPositionChanging` 回调获取数据点索引
- 同时启用 Crosshair 显示十字线
- 通过共享的状态变量 `_isCrosshairVisible` 和 `_selectedData` 实现同步

### 难点2：防止选中放大与十字线冲突

**问题**：启用 `enableSelectionZooming` 后，长按会触发选中放大，与十字线功能冲突。

**解决方案**：
```dart
_zoomPanBehavior = ZoomPanBehavior(
  enableSelectionZooming: false,  // 禁用选中放大
  // 其他缩放功能保持启用
);
```

### 难点3：信息面板闪烁问题

**问题**：用户移动手指时，频繁的 `setState` 导致面板闪烁。

**解决方案**：
1. 使用 `Timer` 实现防抖
2. 使用 `AnimatedOpacity` 添加淡入淡出动画
3. 优化状态比较逻辑，避免不必要的更新

```dart
if (!_isCrosshairVisible || newData != _selectedData) {
  setState(() {
    // 只在状态真正改变时更新
  });
}
```

### 难点4：数据真实性

**问题**：如何生成看起来真实的交易数据？

**解决方案**：
1. 价格波动基于当前价格的百分比（相对波动）
2. High 和 Low 必须包含 Open 和 Close
3. 成交量与价格波动幅度正相关
4. 添加市场趋势偏向（牛市/熊市）

```dart
// 成交量与价格变化正相关
final priceChange = (close - open).abs();
final volumeMultiplier = 1.0 + (priceChange / currentPrice) * 10;
final volume = baseVolume * volumeMultiplier * (0.5 + _random.nextDouble());
```

---

## 10. 扩展与优化建议

### 功能扩展

#### 1. 技术指标

添加常见的技术分析指标：

- **MA（移动平均线）**
  ```dart
  // 计算简单移动平均线
  List<double> calculateSMA(List<double> prices, int period) {
    List<double> sma = [];
    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        sma.add(double.nan);
      } else {
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += prices[i - j];
        }
        sma.add(sum / period);
      }
    }
    return sma;
  }
  ```

- **MACD（指数平滑异同移动平均线）**
- **RSI（相对强弱指标）**
- **布林带（Bollinger Bands）**

#### 2. 实时数据接入

集成真实的交易所 API：

```dart
// 使用 WebSocket 接收实时数据
import 'package:web_socket_channel/web_socket_channel.dart';

class BinanceWebSocketClient {
  late WebSocketChannel channel;
  
  void connect(String symbol) {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@kline_1m'),
    );
    
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      // 解析并更新图表数据
    });
  }
}
```

#### 3. 绘图工具

允许用户在图表上绘制：

- 趋势线
- 水平线
- 斐波那契回调线
- 矩形和文本标注

#### 4. 多图表布局

支持同时显示多个交易对：

```dart
GridView.count(
  crossAxisCount: 2,
  children: [
    CandlestickChartWidget(data: btcData, title: 'BTC/USDT'),
    CandlestickChartWidget(data: ethData, title: 'ETH/USDT'),
    CandlestickChartWidget(data: bnbData, title: 'BNB/USDT'),
    CandlestickChartWidget(data: solData, title: 'SOL/USDT'),
  ],
)
```

### 性能优化

#### 1. 数据分页加载

当数据量很大时，只加载可见区域的数据：

```dart
class ChartDataManager {
  List<CandlestickData> _allData = [];
  int _visibleStart = 0;
  int _visibleEnd = 100;
  
  List<CandlestickData> getVisibleData() {
    return _allData.sublist(_visibleStart, _visibleEnd);
  }
  
  void onZoomChanged(double zoomFactor, double zoomPosition) {
    // 根据缩放级别调整可见数据范围
  }
}
```

#### 2. Canvas 优化

对于超大数据集，考虑使用 CustomPainter 自定义绘制：

```dart
class CandlestickPainter extends CustomPainter {
  final List<CandlestickData> data;
  
  @override
  void paint(Canvas canvas, Size size) {
    // 直接在 Canvas 上绘制蜡烛图
    for (var candle in data) {
      // 绘制蜡烛体
      canvas.drawRect(...);
      // 绘制上下影线
      canvas.drawLine(...);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

#### 3. 使用 Isolate 处理数据

将复杂的数据计算放到后台线程：

```dart
Future<List<CandlestickData>> processDataInBackground(
  List<Map<String, dynamic>> rawData,
) async {
  return await compute(_parseData, rawData);
}

// 在 Isolate 中执行
List<CandlestickData> _parseData(List<Map<String, dynamic>> rawData) {
  return rawData.map((item) => CandlestickData(
    date: DateTime.parse(item['date']),
    open: item['open'],
    high: item['high'],
    low: item['low'],
    close: item['close'],
    volume: item['volume'],
  )).toList();
}
```

### UI/UX 优化

#### 1. 响应式设计

根据屏幕尺寸调整布局：

```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 600) {
    // 平板/桌面布局
    return Row(
      children: [
        Expanded(child: _buildChartView()),
        SizedBox(width: 300, child: _buildOrderBook()),
      ],
    );
  } else {
    // 手机布局
    return Column(
      children: [
        Expanded(child: _buildChartView()),
      ],
    );
  }
}
```

#### 2. 主题切换

支持多种主题：

```dart
enum ChartTheme {
  dark,
  light,
  professional,
  colorblind,
}

class ThemeConfig {
  static ColorScheme getColorScheme(ChartTheme theme) {
    switch (theme) {
      case ChartTheme.dark:
        return ColorScheme(
          background: Color(0xFF0D0D0D),
          bullColor: Color(0xFF26A69A),
          bearColor: Color(0xFFEF5350),
        );
      case ChartTheme.light:
        return ColorScheme(
          background: Color(0xFFFFFFFF),
          bullColor: Color(0xFF4CAF50),
          bearColor: Color(0xFFF44336),
        );
      // ...
    }
  }
}
```

#### 3. 手势增强

添加更多手势支持：

```dart
GestureDetector(
  onDoubleTap: () {
    // 双击重置缩放
    _zoomPanBehavior.reset();
  },
  onLongPressStart: (details) {
    // 长按开始显示十字线
  },
  onLongPressMoveUpdate: (details) {
    // 拖动更新十字线位置
  },
  onLongPressEnd: (details) {
    // 释放隐藏十字线
  },
  child: _buildChart(),
)
```

### 数据持久化

#### 1. 缓存历史数据

```dart
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class CandlestickDataHive extends HiveObject {
  @HiveField(0)
  late int timestamp;
  
  @HiveField(1)
  late double open;
  
  // ...其他字段
}

class DataCache {
  static Future<void> saveData(List<CandlestickData> data) async {
    final box = await Hive.openBox<CandlestickDataHive>('candlestick_cache');
    await box.clear();
    await box.addAll(data.map((d) => d.toHive()).toList());
  }
  
  static Future<List<CandlestickData>> loadData() async {
    final box = await Hive.openBox<CandlestickDataHive>('candlestick_cache');
    return box.values.map((d) => d.toModel()).toList();
  }
}
```

#### 2. 用户偏好设置

```dart
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<void> saveTimeframe(String timeframe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_timeframe', timeframe);
  }
  
  static Future<String> getTimeframe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_timeframe') ?? '1H';
  }
}
```

---

## 总结

本项目展示了如何使用 Flutter 和 Syncfusion Charts 构建专业级的加密货币交易图表应用。核心技术要点包括：

1. **数据模型设计**：标准的 OHLC 结构
2. **数据生成算法**：模拟真实市场行为
3. **图表配置**：Syncfusion 的高级功能
4. **交互实现**：十字光标、缩放、平移
5. **性能优化**：防抖、动画、状态管理
6. **UI设计**：深色主题、专业配色

通过合理的架构设计和组件化开发，项目具有良好的可扩展性和可维护性。后续可以轻松添加技术指标、实时数据接入等高级功能。

---

## 参考资源

- [Syncfusion Flutter Charts Documentation](https://help.syncfusion.com/flutter/cartesian-charts/overview)
- [Flutter 官方文档](https://docs.flutter.dev/)
- [交易所 API 文档](https://binance-docs.github.io/apidocs/spot/en/)
- [技术分析指标](https://www.investopedia.com/terms/t/technicalanalysis.asp)

---

**作者**：Candlestick Chart Development Team  
**最后更新**：2025-11-07  
**版本**：v1.0.0

