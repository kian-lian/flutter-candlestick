# 快速入门指南

本指南将帮助您在 5 分钟内运行并理解这个蜡烛图应用。

## 📋 前置条件检查

在开始之前，请确保您的开发环境已准备好：

```bash
# 检查 Flutter 版本
flutter --version
# 需要：Flutter 3.9.0 或更高版本

# 检查 Dart 版本
dart --version
# 需要：Dart 3.9.0 或更高版本

# 检查可用设备
flutter devices
# 至少需要一个可用设备（模拟器或真机）
```

## 🚀 三步运行

### 步骤 1：安装依赖

```bash
cd syncfusion_candlestick
flutter pub get
```

**预期输出**：
```
Running "flutter pub get" in syncfusion_candlestick...
Resolving dependencies... (1.2s)
Got dependencies!
```

### 步骤 2：启动模拟器（可选）

如果没有连接的设备：

```bash
# Android 模拟器
flutter emulators --launch <emulator_id>

# 或者直接启动默认模拟器
open -a Simulator  # macOS (iOS)
```

### 步骤 3：运行应用

```bash
flutter run
```

**预期输出**：
```
Launching lib/main.dart on iPhone 14 Pro in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app.apk...
Syncing files to device iPhone 14 Pro...
Flutter run key commands.
r Hot reload. 🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on iPhone 14 Pro is available at: ...
The Flutter DevTools debugger and profiler on iPhone 14 Pro is available at: ...
```

**🎉 成功！** 应用现在应该在您的设备上运行了。

## 🎮 快速体验

### 1. 查看不同市场趋势

顶部有三个 Tab：
- **Bullish（牛市）**：价格上涨趋势
- **Neutral（中性）**：价格随机波动
- **Bearish（熊市）**：价格下跌趋势

**操作**：点击不同的 Tab，观察图表变化

### 2. 切换时间周期

在时间周期选择器中，点击不同的按钮：
- **1H**：1小时周期
- **4H**：4小时周期
- **1D**：1天周期
- **1W**：1周周期

**注意**：当前版本中时间周期切换只改变选中状态，数据暂未实际切换

### 3. 使用十字光标

**操作**：长按图表上的任意位置

**效果**：
- 出现十字线（横竖虚线）
- 左上角显示数据面板，包含：
  - 时间
  - O（开盘价）
  - H（最高价）
  - L（最低价）
  - C（收盘价）
  - 涨跌幅百分比

**提示**：保持长按并移动手指，可以查看不同位置的数据

### 4. 缩放和平移

**缩放**：
- 双指捏合：缩小
- 双指展开：放大
- 双击：快速放大

**平移**：
- 单指左右拖动：移动图表查看历史数据

### 5. 刷新数据

**操作**：点击右上角的刷新图标 🔄

**效果**：生成新的随机数据，图表重新渲染

## 📖 核心概念理解

### 什么是蜡烛图（K线图）？

蜡烛图是金融交易中最常用的图表类型，每根"蜡烛"代表一个时间周期内的价格变化：

```
      ↑ 最高价 (High)
      |
   ┌──┴──┐
   │     │  ← 蜡烛体（Candle Body）
   │     │    - 顶部：收盘价或开盘价（取较高者）
   └──┬──┘    - 底部：开盘价或收盘价（取较低者）
      |
      ↓ 最低价 (Low)
```

**颜色含义**：
- 🟢 **绿色/青色**（阳线）：收盘价 > 开盘价（涨）
- 🔴 **红色**（阴线）：收盘价 < 开盘价（跌）

### OHLC 数据

每个数据点包含四个关键价格：

- **O (Open)**：开盘价 - 时间周期开始时的价格
- **H (High)**：最高价 - 时间周期内的最高价格
- **L (Low)**：最低价 - 时间周期内的最低价格
- **C (Close)**：收盘价 - 时间周期结束时的价格

**示例**：
```
2024-11-07 10:00 - 11:00 的 1 小时数据：
O: $45,000  (10:00 的价格)
H: $45,500  (这一小时内最高到过 $45,500)
L: $44,800  (这一小时内最低到过 $44,800)
C: $45,200  (11:00 的价格)
```

### 成交量（Volume）

图表下方的柱状图表示每个时间周期内的交易量：
- 柱子越高，交易越活跃
- 颜色与蜡烛图对应（绿色/红色）

## 🔍 深入探索

### 查看代码结构

**1. 数据模型**

查看 `lib/models/candlestick_data.dart`：

```dart
class CandlestickData {
  final DateTime date;   // 时间
  final double open;     // 开盘价
  final double high;     // 最高价
  final double low;      // 最低价
  final double close;    // 收盘价
  final double volume;   // 成交量
  
  bool get isBullish => close >= open;  // 是否阳线
}
```

**2. 数据生成器**

查看 `lib/data/sample_data_provider.dart`：

```dart
// 生成牛市数据
SampleDataProvider.generateBullishData(count: 100)

// 生成熊市数据
SampleDataProvider.generateBearishData(count: 100)

// 生成比特币模拟数据
SampleDataProvider.generateBitcoinData(count: 100)
```

**3. 图表组件**

查看 `lib/widgets/candlestick_chart_widget.dart`：

主要部分：
- `_buildCandlestickChart()` - 主蜡烛图
- `_buildVolumeChart()` - 成交量图
- `_buildCrosshairInfoPanel()` - 十字光标信息面板

## 🎯 常见问题

### Q1: 应用启动失败

**解决方案**：

```bash
# 清理构建缓存
flutter clean

# 重新获取依赖
flutter pub get

# 重新运行
flutter run
```

### Q2: 没有可用设备

**解决方案**：

```bash
# 查看可用设备
flutter devices

# 如果列表为空，启动模拟器：
# iOS (macOS only)
open -a Simulator

# Android
flutter emulators
flutter emulators --launch <emulator_id>
```

### Q3: Syncfusion 许可证警告

**现象**：应用运行时显示 Syncfusion 许可证警告

**说明**：
- 这是正常的，因为 Syncfusion 是商业库
- 开发和学习用途可以忽略此警告
- 生产环境需要购买许可证

**临时解决**（仅开发环境）：

在 `main.dart` 的 `main()` 函数中添加：

```dart
import 'package:syncfusion_flutter_core/core.dart';

void main() {
  // 注册 Syncfusion 许可证（需要有效的许可证密钥）
  // SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY');
  
  runApp(const MyApp());
}
```

### Q4: 热重载不工作

**解决方案**：

```bash
# 在运行的终端中按键：
r  # 热重载（Hot Reload）
R  # 热重启（Hot Restart）
```

如果仍然不工作：
```bash
# 停止应用（按 q）
# 重新运行
flutter run
```

### Q5: 图表显示异常

**可能原因**：
- 数据为空
- 时间格式不正确
- 屏幕尺寸太小

**调试方法**：

在 `candlestick_chart_widget.dart` 中添加调试输出：

```dart
@override
Widget build(BuildContext context) {
  print('Data count: ${widget.data.length}');
  if (widget.data.isNotEmpty) {
    print('First data: ${widget.data.first.date} - ${widget.data.first.close}');
  }
  
  return Container(...);
}
```

## 🛠️ 自定义示例

### 修改主题色

编辑 `lib/main.dart` 中的主题配置：

```dart
theme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0D0D0D),  // 修改背景色
  primaryColor: const Color(0xFF26A69A),              // 修改主色调
),
```

### 修改蜡烛图颜色

编辑 `lib/widgets/candlestick_chart_widget.dart`：

```dart
CandleSeries<CandlestickData, DateTime>(
  bearColor: const Color(0xFFEF5350),  // 阴线颜色（改这里）
  bullColor: const Color(0xFF26A69A),  // 阳线颜色（改这里）
)
```

### 更改数据点数量

编辑 `lib/main.dart` 中的数据加载方法：

```dart
void _loadData() {
  setState(() {
    _currentData = SampleDataProvider.generateBitcoinData(
      count: 200,  // 改为 200 个数据点（默认 100）
    );
  });
}
```

### 修改时间格式

编辑 `lib/widgets/candlestick_chart_widget.dart`：

```dart
primaryXAxis: DateTimeAxis(
  dateFormat: DateFormat('MM/dd HH:mm'),  // 改为你喜欢的格式
  // 例如：
  // DateFormat('yyyy-MM-dd')  // 2024-11-07
  // DateFormat('HH:mm')       // 14:30
  // DateFormat('MM月dd日')     // 11月07日
),
```

## 📚 下一步

现在您已经成功运行了应用，可以：

1. **阅读详细文档**：
   - [实现指南](IMPLEMENTATION_GUIDE.md) - 了解技术细节
   - [架构设计](ARCHITECTURE.md) - 了解系统架构

2. **尝试扩展功能**：
   - 添加移动平均线（MA）
   - 集成真实交易所 API
   - 添加更多技术指标

3. **学习 Syncfusion Charts**：
   - [官方文档](https://help.syncfusion.com/flutter/cartesian-charts/overview)
   - [示例库](https://flutter.syncfusion.com/#/cartesian-charts/chart-types/line/default-line-chart)

4. **参考资源**：
   - [Flutter 官方文档](https://docs.flutter.dev/)
   - [Dart 语言教程](https://dart.dev/guides)
   - [金融图表教程](https://www.investopedia.com/terms/c/candlestick.asp)

## 💡 开发提示

### 开启调试工具

```bash
# 启动应用后，在浏览器中打开 DevTools
flutter run
# 然后在终端中会显示 DevTools 的 URL，在浏览器中打开它
```

### 使用 Hot Reload

修改代码后，按 `r` 键即可看到更改，无需重启应用：

```dart
// 修改前
Text('Hello', style: TextStyle(color: Colors.white))

// 修改后（按 r 后立即生效）
Text('Hello World', style: TextStyle(color: Colors.blue))
```

### 调试打印

使用 `print()` 或 `debugPrint()` 输出日志：

```dart
void _onTrackballPositionChanging(TrackballArgs args) {
  debugPrint('Trackball position: ${args.position}');
  // ...
}
```

### 性能分析

```bash
# 启动性能分析模式
flutter run --profile

# 然后在 DevTools 中查看性能数据
```

## 🎓 学习路径建议

### 初级（已完成 ✅）

- [x] 运行应用
- [x] 理解基本概念
- [x] 体验交互功能

### 中级（推荐）

- [ ] 阅读完整实现文档
- [ ] 理解状态管理
- [ ] 修改主题和颜色
- [ ] 自定义数据生成逻辑

### 高级

- [ ] 添加技术指标
- [ ] 集成实时数据 API
- [ ] 实现绘图工具
- [ ] 性能优化

## 🆘 获取帮助

如果遇到问题：

1. **查看文档**：
   - [README.md](README.md)
   - [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
   - [ARCHITECTURE.md](ARCHITECTURE.md)

2. **搜索错误**：
   - 将错误信息复制到 Google 搜索
   - 在 StackOverflow 上搜索相关问题

3. **提交 Issue**：
   - 描述问题
   - 附上错误截图
   - 提供复现步骤

4. **社区资源**：
   - [Flutter 中文社区](https://flutter.cn/)
   - [Flutter 官方 Discord](https://discord.gg/flutter)
   - [Syncfusion 论坛](https://www.syncfusion.com/forums/flutter)

---

**祝您学习愉快！🎉**

如果这个项目对您有帮助，请给个 ⭐️！

---

**最后更新**：2025-11-07  
**版本**：v1.0.0

