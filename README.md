# Syncfusion Candlestick Chart

一个功能完整的加密货币蜡烛图（K线图）应用，基于 Flutter 和 Syncfusion Charts 构建。

![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.9.0+-blue.svg)
![Syncfusion](https://img.shields.io/badge/Syncfusion-28.1.33-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 📱 功能特性

- ✅ **专业蜡烛图展示**：标准 OHLC（开高低收）数据可视化
- ✅ **成交量柱状图**：与价格图联动的成交量展示
- ✅ **多种市场趋势**：支持牛市、中性、熊市三种市场模拟
- ✅ **时间周期切换**：1小时、4小时、1天、1周多种周期
- ✅ **交互式图表**：
  - 双指缩放（Pinch to zoom）
  - 平移拖动（Pan）
  - 双击快速缩放
  - 长按十字光标
- ✅ **实时数据面板**：长按显示详细 OHLC 数据和涨跌幅
- ✅ **深色主题**：专业的交易所风格 UI 设计
- ✅ **流畅动画**：60 FPS 流畅体验

## 🎯 预览

### 主界面
- 深色主题，护眼舒适
- 清晰的价格信息展示
- 直观的操作提示

### 交互功能
- 十字光标精准定位
- 实时数据悬浮面板
- 平滑的缩放和平移

## 🏗️ 技术架构

### 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Flutter | ^3.9.0 | 跨平台 UI 框架 |
| Dart | ^3.9.0 | 编程语言 |
| Syncfusion Flutter Charts | ^28.1.33 | 专业图表库 |
| intl | ^0.19.0 | 国际化和日期格式化 |

### 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/                            # 数据模型
│   └── candlestick_data.dart         # 蜡烛图数据模型
├── data/                              # 数据层
│   └── sample_data_provider.dart     # 数据生成器
└── widgets/                           # UI 组件
    └── candlestick_chart_widget.dart # 蜡烛图组件
```

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.9.0 或更高版本
- Dart SDK 3.9.0 或更高版本
- Android Studio / VS Code
- Android SDK（Android 平台）或 Xcode（iOS 平台）

### 安装步骤

1. **克隆项目**

```bash
git clone <repository_url>
cd syncfusion_candlestick
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行应用**

```bash
# 运行在默认设备
flutter run

# 指定设备运行
flutter run -d <device_id>

# 查看可用设备
flutter devices
```

### 构建发布版本

```bash
# Android APK
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

## 📚 详细文档

- **[实现指南](IMPLEMENTATION_GUIDE.md)** - 详细的技术实现说明
- **[架构设计](ARCHITECTURE.md)** - 系统架构和数据流程

## 💡 核心功能说明

### 1. 蜡烛图展示

使用 Syncfusion 的 `CandleSeries` 实现标准蜡烛图：
- 阳线（涨）：青绿色 `#26A69A`
- 阴线（跌）：柔和红色 `#EF5350`
- 自动适应数据范围
- 流畅的动画过渡

### 2. 数据生成

内置多种数据生成策略：

```dart
// 牛市数据（上涨趋势）
SampleDataProvider.generateBullishData(count: 100, startPrice: 45000)

// 熊市数据（下跌趋势）
SampleDataProvider.generateBearishData(count: 100, startPrice: 48000)

// 比特币模拟数据
SampleDataProvider.generateBitcoinData(count: 100)

// 以太坊模拟数据
SampleDataProvider.generateEthereumData(count: 100)
```

### 3. 交互行为

#### 缩放和平移

```dart
ZoomPanBehavior(
  enablePinching: true,           // 双指缩放
  enableDoubleTapZooming: true,   // 双击缩放
  enablePanning: true,            // 拖动平移
  zoomMode: ZoomMode.x,           // 横向缩放
)
```

#### 十字光标

```dart
CrosshairBehavior(
  enable: true,
  activationMode: ActivationMode.longPress,  // 长按激活
  lineType: CrosshairLineType.both,          // 横竖十字线
  lineDashArray: const [5, 5],               // 虚线样式
)
```

#### 数据定位

```dart
TrackballBehavior(
  enable: true,
  activationMode: ActivationMode.longPress,
  // 精准定位到最近的数据点
)
```

## 🎨 UI 设计

### 颜色方案

| 用途 | 颜色代码 | 说明 |
|------|---------|------|
| 背景色 | `#0D0D0D` | 深黑色，护眼舒适 |
| 卡片背景 | `#1A1A1A` | 浅黑色 |
| 主题色 | `#26A69A` | 青绿色（涨） |
| 强调色 | `#EF5350` | 柔和红色（跌） |

### 响应式设计

- 适配手机和平板
- 横屏和竖屏支持
- 自动调整图表尺寸

## 🔧 自定义和扩展

### 添加自定义数据源

```dart
// 替换数据提供者
class MyCustomDataProvider {
  static List<CandlestickData> fetchDataFromAPI() {
    // 从真实 API 获取数据
    // 例如：币安、火币等交易所 API
  }
}
```

### 添加技术指标

```dart
// 添加移动平均线
LineSeries<CandlestickData, DateTime>(
  dataSource: widget.data,
  xValueMapper: (data, _) => data.date,
  yValueMapper: (data, _) => calculateMA(data, period: 20),
  color: Colors.yellow,
)
```

### 连接实时数据

```dart
// 使用 WebSocket 连接交易所
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeDataService {
  late WebSocketChannel channel;
  
  void connect(String symbol) {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/${symbol}@kline_1m'),
    );
    
    channel.stream.listen((message) {
      // 解析并更新图表数据
    });
  }
}
```

## 🐛 已知问题

- 暂无

## 🗺️ 路线图

- [ ] 添加技术指标（MA、MACD、RSI、布林带等）
- [ ] 集成真实交易所 API
- [ ] 支持绘图工具（趋势线、水平线等）
- [ ] 添加多币种对比视图
- [ ] 支持更多时间周期
- [ ] 数据导出功能
- [ ] 价格提醒功能

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [Syncfusion](https://www.syncfusion.com/flutter-widgets) - 强大的图表库
- [Dart](https://dart.dev/) - 现代化的编程语言

## 📞 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 提交 Issue
- 发起 Discussion
- 发送邮件

## 🌟 Star History

如果这个项目对您有帮助，请给它一个 ⭐️！

---

**开发者**：Candlestick Chart Team  
**最后更新**：2025-11-07  
**版本**：v1.0.0
