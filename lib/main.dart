import 'package:flutter/material.dart';
import 'ci_service.dart'; // API fetch service
import 'package:fl_chart/fl_chart.dart'; // Chart library

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Intensity Dashboard',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromRGBO(95, 247, 194, 1),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(95, 247, 194, 1),
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900],
        ),
      ),
      home: const MyHomePage(title: 'Carbon Intensity Dashboard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentIntensity = 0;
  List<Map<String, dynamic>> halfHourlyData = [];
  final CarbonIntensityService apiService = CarbonIntensityService();

  @override
  void initState() {
    super.initState();
    fetchCarbonData(); // Fetch data on initialization
  }

  Future<void> fetchCarbonData() async {
    try {
      final intensityData = await apiService.fetchCurrentIntensity();
      final halfHourly = await apiService.fetchHalfHourlyIntensity();
      setState(() {
        currentIntensity = intensityData['actual'];
        halfHourlyData = halfHourly.map((data) => {
          'time': data['from'], // Adjust time format if needed
          'intensity': data['intensity']['actual'] ?? data['intensity']['forecast'],
          'wasForecast': data['intensity']['actual'] == null,
        }).toList();
      });
    } catch (e) {
      print('Error fetching data: $e');
      //diplay a pop up
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
        title: const Text('Error'),
        content: Text('Error fetching data: $e'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
          Navigator.of(context).pop();
            },
          ),
        ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
children: <Widget>[
  currentIntensity == 0
      ? const CircularProgressIndicator()
      : Column(
          children: [
            const SizedBox(height: 20),

            Text(
              'Current Carbon Intensity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$currentIntensity gCO₂/kWh',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
  const SizedBox(height: 20),
            
            // Graph for half-hourly data
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: halfHourlyData.isEmpty
                    ? const Center(child: Text('Loading half-hourly data...'))
                    : Column(
                        children: [
                          const Text(
                            'Carbon Intensity Today',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  // Actual intensity data - solid line
                                  LineChartBarData(
                                    spots: halfHourlyData
                                        .where((data) => !data['wasForecast'])
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value['intensity'].toDouble()))
                                        .toList(),
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true),
                                    barWidth: 2,
                                  ),
                                  // Forecasted intensity data - dashed line
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(
                                        halfHourlyData
                                            .indexWhere((data) => data['wasForecast'])
                                            .toDouble() - 1,
                                        halfHourlyData
                                            .where((data) => !data['wasForecast'])
                                            .last['intensity']
                                            .toDouble(),
                                      ),
                                      ...halfHourlyData
                                          .where((data) => data['wasForecast'])
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) => FlSpot(
                                              (halfHourlyData.indexWhere((data) => data['wasForecast']) + entry.key).toDouble(),
                                              entry.value['intensity'].toDouble()))
                                          .toList(),
                                    ],
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                    barWidth: 2,
                                    dashArray: [5, 5],
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  enabled: false, // Disables pointer on hover
                                ), 
                                minY: 0,
                                maxY: halfHourlyData.fold(
                                        0,
                                        (max, data) => data['intensity'] > max
                                            ? data['intensity']
                                            : max) + 50,
                                titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 50,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, _) =>
                                        Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54)),
                                    ),
                                    ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 10,
                                      getTitlesWidget: (value, _) =>
                                          Text(halfHourlyData[value.toInt()]['time'].substring(11, 16)),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.white54, width: 1),
                                ),
                                gridData: FlGridData(show: false),
                              ),
                            ),
                          ),
                          // Custom Legend Row
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Actual Data Legend
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 2,
                                      color: Colors.cyan,
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Actual Data',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                // Forecasted Data Legend
                                Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 2,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.cyan,
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Forecasted Data',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
