import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/candlestick_chart_widget.dart';
import 'data/sample_data_provider.dart';
import 'models/candlestick_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Candlestick Chart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: const Color(0xFF26A69A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
      ),
      home: const CandlestickChartPage(),
    );
  }
}

class CandlestickChartPage extends StatefulWidget {
  const CandlestickChartPage({super.key});

  @override
  State<CandlestickChartPage> createState() => _CandlestickChartPageState();
}

class _CandlestickChartPageState extends State<CandlestickChartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CandlestickData> _currentData = [];
  String _currentPair = 'BTC/USDT';

  final List<String> _timeframes = ['1H', '4H', '1D', '1W'];
  int _selectedTimeframe = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _currentData = SampleDataProvider.generateBitcoinData(count: 100);
    });
  }

  void _changeMarketTrend(int index) {
    setState(() {
      switch (index) {
        case 0:
          _currentPair = 'BTC/USDT';
          _currentData = SampleDataProvider.generateBullishData(
            count: 100,
            startPrice: 45000,
          );
          break;
        case 1:
          _currentPair = 'ETH/USDT';
          _currentData = SampleDataProvider.generateEthereumData(count: 100);
          break;
        case 2:
          _currentPair = 'BTC/USDT';
          _currentData = SampleDataProvider.generateBearishData(
            count: 100,
            startPrice: 48000,
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text(
            'Crypto Trading Chart',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            onTap: _changeMarketTrend,
            indicatorColor: const Color(0xFF26A69A),
            labelColor: const Color(0xFF26A69A),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Bullish'),
              Tab(text: 'Neutral'),
              Tab(text: 'Bearish'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChartView(),
            _buildChartView(),
            _buildChartView(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartView() {
    return Column(
              children: [
                // Timeframe selector
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Timeframe:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_timeframes.length, (
                              index,
                            ) {
                              final isSelected = _selectedTimeframe == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(_timeframes[index]),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTimeframe = index;
                                    });
                                  },
                                  selectedColor: const Color(0xFF26A69A),
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _currentData.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF26A69A),
                            ),
                          )
                        : CandlestickChartWidget(
                            data: _currentData,
                            title: _currentPair,
                          ),
                  ),
                ),

                // Chart controls info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chart Controls:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildControlItem('Pinch', 'Zoom in/out'),
                      _buildControlItem('Swipe', 'Move chart left/right'),
                      _buildControlItem('Tap', 'Show OHLC tooltip'),
                      _buildControlItem('Long press', 'Show crosshair & drag to move'),
                      _buildControlItem('Double tap', 'Quick zoom'),
                    ],
                  ),
                ),
              ],
            );
  }

  Widget _buildControlItem(String action, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: Color(0xFF26A69A),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
