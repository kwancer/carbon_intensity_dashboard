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
  List<Map<String, dynamic>> halfHourlyData = []; // Placeholder for half-hourly data
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
        currentIntensity = intensityData['forecast'];
        halfHourlyData = halfHourly.map((data) => {
          'time': data['from'], // Adjust time format if needed
          'intensity': data['intensity']['forecast']
        }).toList();
      });
    } catch (e) {
      print('Error fetching data: $e');
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
                : Text(
                    'Current Carbon Intensity: $currentIntensity gCO2/kWh',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Theme.of(context).primaryColor),
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
                                  LineChartBarData(
                                    spots: halfHourlyData
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => FlSpot(
                                              entry.key.toDouble(),
                                              entry.value['intensity']
                                                  .toDouble()),
                                        )
                                        .toList(),
                                    isCurved: true,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: true),
                                    barWidth: 2,
                                  ),
                                ],
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
                                      getTitlesWidget: (value, _) =>
                                          Text(value.toInt().toString(),
                                              style: const TextStyle(
                                                  color: Colors.white54)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 10,
                                      getTitlesWidget: (value, _) =>
                                          Text(halfHourlyData[value.toInt()]
                                                  ['time']
                                              .substring(11, 16)),
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                      color: Colors.white54, width: 1),
                                ),
                                gridData: FlGridData(show: false),
                              ),
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
