# 架构设计文档

## 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                         应用层 (main.dart)                    │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  MyApp (MaterialApp)                                  │   │
│  │    └── CandlestickChartPage (StatefulWidget)         │   │
│  │         ├── TabController (牛市/中性/熊市)             │   │
│  │         ├── Timeframe Selector (1H/4H/1D/1W)         │   │
│  │         └── CandlestickChartWidget                   │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    UI组件层 (widgets/)                        │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  CandlestickChartWidget (StatefulWidget)             │   │
│  │    ├── _buildChartHeader()      (价格信息头部)         │   │
│  │    ├── _buildCandlestickChart() (主蜡烛图)            │   │
│  │    │    ├── SfCartesianChart                         │   │
│  │    │    ├── CandleSeries                             │   │
│  │    │    ├── ZoomPanBehavior    (缩放和平移)          │   │
│  │    │    ├── TrackballBehavior  (数据点定位)          │   │
│  │    │    └── CrosshairBehavior  (十字线)              │   │
│  │    ├── _buildVolumeChart()      (成交量图)            │   │
│  │    │    ├── SfCartesianChart                         │   │
│  │    │    └── ColumnSeries                             │   │
│  │    └── _buildCrosshairInfoPanel() (悬浮信息面板)     │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    数据层 (data/ & models/)                   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  SampleDataProvider (数据生成器)                       │   │
│  │    ├── generateCandlestickData() (基础数据生成)        │   │
│  │    ├── generateBullishData()     (牛市数据)           │   │
│  │    ├── generateBearishData()     (熊市数据)           │   │
│  │    ├── generateRangingData()     (横盘数据)           │   │
│  │    ├── generateBitcoinData()     (比特币模拟)         │   │
│  │    └── generateEthereumData()    (以太坊模拟)         │   │
│  └───────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  CandlestickData (数据模型)                            │   │
│  │    ├── date: DateTime     (时间)                      │   │
│  │    ├── open: double       (开盘价)                    │   │
│  │    ├── high: double       (最高价)                    │   │
│  │    ├── low: double        (最低价)                    │   │
│  │    ├── close: double      (收盘价)                    │   │
│  │    ├── volume: double     (成交量)                    │   │
│  │    ├── isBullish: bool    (是否阳线)                  │   │
│  │    └── isBearish: bool    (是否阴线)                  │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    第三方库 (dependencies)                    │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  syncfusion_flutter_charts  (图表渲染引擎)             │   │
│  │  intl                       (日期格式化)               │   │
│  │  flutter                    (UI框架)                  │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 数据流向图

```
┌─────────────┐
│  用户操作    │
│ - 选择Tab   │
│ - 选择时间   │
│ - 刷新数据   │
└──────┬──────┘
       ↓
┌──────────────────────┐
│  _CandlestickChart   │
│  PageState           │
│  ├── _currentData    │────────┐
│  ├── _currentPair    │        │
│  └── _selectedTime   │        │
└──────┬───────────────┘        │
       ↓                        │
┌──────────────────────┐        │
│  SampleDataProvider  │        │
│  .generateData()     │        │
└──────┬───────────────┘        │
       ↓                        │
┌──────────────────────┐        │
│  List<Candlestick    │        │
│  Data>               │────────┘
└──────┬───────────────┘
       ↓
┌──────────────────────────────────┐
│  CandlestickChartWidget          │
│  (接收数据并渲染)                  │
│  ├── widget.data                 │
│  └── widget.title                │
└──────┬───────────────────────────┘
       ↓
┌──────────────────────────────────┐
│  SfCartesianChart                │
│  (Syncfusion 图表渲染)            │
│  ├── CandleSeries (蜡烛图)        │
│  ├── ColumnSeries (成交量)        │
│  └── Behaviors (交互行为)         │
└──────┬───────────────────────────┘
       ↓
┌──────────────────────────────────┐
│  屏幕显示                         │
└──────────────────────────────────┘
```

---

## 用户交互流程图

### 十字光标交互流程

```
用户长按屏幕
     ↓
┌─────────────────────────────────┐
│  TrackballBehavior              │
│  onTrackballPositionChanging    │
└────────────┬────────────────────┘
             ↓
    ┌────────────────┐
    │ 获取触摸点坐标  │
    └────────┬───────┘
             ↓
    ┌────────────────┐
    │ 查找最近数据点  │
    │ dataPointIndex │
    └────────┬───────┘
             ↓
        ┌────────┐
        │ 有效？  │
        └───┬────┘
          是│    │否
            ↓    ↓
    ┌──────────┐  ┌──────────┐
    │ 更新状态  │  │ 隐藏面板  │
    │ setState │  │ setState │
    └─────┬────┘  └──────────┘
          ↓
    ┌──────────────┐
    │ 防抖延迟 16ms │
    └──────┬───────┘
           ↓
    ┌─────────────────────────┐
    │ 渲染十字线                │
    │ CrosshairBehavior        │
    └─────────────────────────┘
           ↓
    ┌─────────────────────────┐
    │ 显示信息面板              │
    │ _buildCrosshairInfoPanel│
    │ ├── 时间                 │
    │ ├── OHLC 数据            │
    │ └── 涨跌幅               │
    └─────────────────────────┘
           ↓
    ┌─────────────────────────┐
    │ 用户释放手指              │
    └──────┬──────────────────┘
           ↓
    ┌─────────────────────────┐
    │ 隐藏十字线和面板          │
    │ setState                │
    │ _isCrosshairVisible=false│
    └─────────────────────────┘
```

### 缩放和平移流程

```
用户手势
    ├─ 双指捏合 (Pinch)
    │      ↓
    │  ┌──────────────┐
    │  │ ZoomPanBehavior │
    │  │ enablePinching  │
    │  └────────┬─────────┘
    │           ↓
    │      横向缩放图表
    │
    ├─ 单指拖动 (Pan)
    │      ↓
    │  ┌──────────────┐
    │  │ ZoomPanBehavior │
    │  │ enablePanning   │
    │  └────────┬─────────┘
    │           ↓
    │      左右平移图表
    │
    └─ 双击 (Double Tap)
           ↓
       ┌──────────────────┐
       │ ZoomPanBehavior     │
       │ enableDoubleTap     │
       │ Zooming             │
       └────────┬───────────┘
                ↓
           快速放大图表
```

---

## 状态管理流程

### 页面级状态 (_CandlestickChartPageState)

```dart
class _CandlestickChartPageState {
  // 状态变量
  TabController _tabController;          // Tab 控制器
  List<CandlestickData> _currentData;    // 当前图表数据
  String _currentPair;                    // 当前交易对
  int _selectedTimeframe;                 // 选中的时间周期
  
  // 状态更新方法
  void _loadData() {
    setState(() {
      _currentData = SampleDataProvider.generateData();
    });
  }
  
  void _changeMarketTrend(int index) {
    setState(() {
      // 根据 Tab 切换数据
      switch (index) {
        case 0: /* 牛市 */ break;
        case 1: /* 中性 */ break;
        case 2: /* 熊市 */ break;
      }
    });
  }
}
```

### 组件级状态 (_CandlestickChartWidgetState)

```dart
class _CandlestickChartWidgetState {
  // 交互行为
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;
  late CrosshairBehavior _crosshairBehavior;
  
  // 十字光标状态
  bool _isCrosshairVisible = false;
  CandlestickData? _selectedData;
  Timer? _debounceTimer;
  
  // 状态更新方法
  void _onTrackballPositionChanging(TrackballArgs args) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 16), () {
      setState(() {
        _isCrosshairVisible = true;
        _selectedData = /* 选中的数据点 */;
      });
    });
  }
}
```

---

## 组件通信机制

```
┌────────────────────────────────────┐
│  CandlestickChartPage              │
│  (父组件)                           │
│  ┌──────────────────────────────┐  │
│  │ State:                       │  │
│  │ - _currentData               │  │
│  │ - _currentPair               │  │
│  └──────────────────────────────┘  │
└────────────┬───────────────────────┘
             │
             │ Props 传递
             ↓
┌────────────────────────────────────┐
│  CandlestickChartWidget            │
│  (子组件)                           │
│  ┌──────────────────────────────┐  │
│  │ Props:                       │  │
│  │ - data: List<Candlestick>   │  │
│  │ - title: String             │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │ State:                       │  │
│  │ - _isCrosshairVisible       │  │
│  │ - _selectedData             │  │
│  └──────────────────────────────┘  │
└────────────────────────────────────┘
```

**通信方式**：
- 父 → 子：通过 `widget.data` 和 `widget.title` 传递数据
- 子 → 父：暂无需要（如需可使用回调函数）

---

## 关键算法详解

### 1. 蜡烛图数据生成算法

```
输入：count (数据点数量), startPrice (起始价格)
输出：List<CandlestickData>

算法步骤：
1. 初始化
   - currentPrice = startPrice
   - currentTime = 现在 - (count * interval)

2. 循环生成每个数据点 (i = 0 to count-1):
   a. 计算波动率
      volatility = currentPrice × 0.02
   
   b. 生成价格趋势（随机游走）
      trend = (random(0,1) - 0.5) × volatility
   
   c. 计算 OHLC
      open = currentPrice
      close = currentPrice + trend
      high = max(open, close) + random(0, range)
      low = min(open, close) - random(0, range)
   
   d. 计算成交量（与价格变动相关）
      priceChange = |close - open|
      volumeMultiplier = 1.0 + (priceChange / currentPrice) × 10
      volume = baseVolume × volumeMultiplier × random(0.5, 1.5)
   
   e. 创建数据点
      data.add(CandlestickData(...))
   
   f. 更新状态
      currentPrice = close
      currentTime += interval

3. 返回 data
```

### 2. 防抖算法

```
防抖目的：减少频繁的状态更新，提高性能，避免闪烁

算法：
1. 定义防抖延迟 DEBOUNCE_DELAY = 16ms

2. 当事件触发时：
   a. 取消之前的定时器（如果存在）
      if (_debounceTimer != null) {
        _debounceTimer.cancel();
      }
   
   b. 创建新的定时器
      _debounceTimer = Timer(DEBOUNCE_DELAY, () {
        // 执行实际的状态更新
        setState(() {
          // 更新状态
        });
      });

3. 组件销毁时清理
   @override
   void dispose() {
     _debounceTimer?.cancel();
     super.dispose();
   }

效果：
- 多次快速触发只执行最后一次
- 减少 setState 调用次数
- 平滑用户体验
```

### 3. 十字光标数据定位算法

```
目标：根据触摸点找到最近的数据点

输入：touchX (触摸 X 坐标), chartData (所有数据点)
输出：dataPointIndex (最近数据点的索引)

算法（由 Syncfusion 内部实现）：
1. 将触摸坐标转换为图表坐标系
   chartX = screenToChartCoordinate(touchX)

2. 将图表坐标转换为数据坐标
   dataX = chartXToDataX(chartX)  // DateTime 值

3. 二分查找最近的数据点
   left = 0, right = chartData.length - 1
   while (left <= right) {
     mid = (left + right) / 2
     if (chartData[mid].date < dataX) {
       left = mid + 1
     } else if (chartData[mid].date > dataX) {
       right = mid - 1
     } else {
       return mid
     }
   }
   
   // 返回最近的索引
   return left 或 right (取决于哪个更近)

4. 返回 dataPointIndex
```

---

## 性能考虑

### 1. 渲染性能

| 场景 | 数据量 | 渲染方式 | 性能 |
|------|--------|---------|------|
| 小数据集 | < 1000 点 | Syncfusion 默认渲染 | 60 FPS |
| 中数据集 | 1000-5000 点 | 启用数据抽样 | 50-60 FPS |
| 大数据集 | > 5000 点 | 自定义 Canvas 绘制 | 40-50 FPS |

### 2. 内存占用

```
单个 CandlestickData 对象：
- DateTime: 8 bytes
- double × 5: 40 bytes (open, high, low, close, volume)
- 对象头: ~16 bytes
- 总计: ~64 bytes

1000 个数据点: ~64 KB
10000 个数据点: ~640 KB
```

### 3. 优化策略

```dart
// 1. 数据抽样（降采样）
List<CandlestickData> downsample(List<CandlestickData> data, int targetSize) {
  if (data.length <= targetSize) return data;
  
  final step = data.length ~/ targetSize;
  return [
    for (int i = 0; i < data.length; i += step)
      data[i]
  ];
}

// 2. 懒加载（虚拟滚动）
class LazyChartData {
  final List<CandlestickData> _allData;
  int _visibleStart = 0;
  int _visibleEnd = 100;
  
  List<CandlestickData> get visibleData => 
    _allData.sublist(_visibleStart, _visibleEnd);
}

// 3. 缓存计算结果
class ChartDataCache {
  final Map<String, List<double>> _cache = {};
  
  List<double> getSMA(int period) {
    final key = 'sma_$period';
    if (_cache.containsKey(key)) return _cache[key]!;
    
    final result = calculateSMA(period);
    _cache[key] = result;
    return result;
  }
}
```

---

## 测试策略

### 1. 单元测试

```dart
// 测试数据模型
test('CandlestickData should correctly identify bullish candle', () {
  final data = CandlestickData(
    date: DateTime.now(),
    open: 100,
    high: 110,
    low: 95,
    close: 105,
    volume: 1000,
  );
  
  expect(data.isBullish, true);
  expect(data.isBearish, false);
});

// 测试数据生成器
test('SampleDataProvider should generate correct number of data points', () {
  final data = SampleDataProvider.generateCandlestickData(count: 50);
  expect(data.length, 50);
});
```

### 2. Widget 测试

```dart
testWidgets('CandlestickChartWidget should display chart', (WidgetTester tester) async {
  final testData = SampleDataProvider.generateBitcoinData(count: 10);
  
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: CandlestickChartWidget(data: testData),
    ),
  ));
  
  // 验证图表已渲染
  expect(find.byType(SfCartesianChart), findsWidgets);
});
```

### 3. 集成测试

```dart
testWidgets('Full user flow test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // 1. 验证初始状态
  expect(find.text('Bullish'), findsOneWidget);
  
  // 2. 点击 Neutral tab
  await tester.tap(find.text('Neutral'));
  await tester.pumpAndSettle();
  
  // 3. 验证数据已更新
  expect(find.text('ETH/USDT'), findsOneWidget);
  
  // 4. 点击刷新按钮
  await tester.tap(find.byIcon(Icons.refresh));
  await tester.pumpAndSettle();
  
  // 5. 验证数据已刷新
  // ...
});
```

---

## 部署清单

### 开发环境

- [ ] Flutter SDK 3.9.0+
- [ ] Dart SDK 3.9.0+
- [ ] Android Studio / VS Code
- [ ] Android SDK (Android 平台)
- [ ] Xcode (iOS 平台)

### 依赖安装

```bash
flutter pub get
```

### 构建命令

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 发布前检查

- [ ] 所有测试通过
- [ ] 无 linter 错误
- [ ] 性能测试通过（60 FPS）
- [ ] 内存泄漏检查
- [ ] 多设备测试（手机、平板）
- [ ] 多平台测试（Android、iOS）
- [ ] 版本号更新
- [ ] 更新日志编写

---

**文档版本**：v1.0.0  
**最后更新**：2025-11-07

