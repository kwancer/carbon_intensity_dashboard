import 'package:flutter/material.dart';

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
  List<Map<String, dynamic>> halfHourlyData = []; // Placeholder for API data

  @override
  void initState() {
    super.initState();
    fetchCarbonData(); // Fetch data on initialization
  }

  // Simulate fetching data (replace with actual API integration)
  Future<void> fetchCarbonData() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulated delay
    setState(() {
      currentIntensity = 250; // Example data
      halfHourlyData = [
        {'time': '00:00', 'intensity': 200},
        {'time': '00:30', 'intensity': 210},
        // More data points here...
      ];
    });
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
            // Display current intensity with FutureBuilder
            FutureBuilder(
              future: fetchCarbonData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text(
                    'Current Carbon Intensity: $currentIntensity gCO2/kWh',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).primaryColor),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            
            // Half-hourly data graph placeholder
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
                    : const Column(
                        children: [
                          Text(
                            'Carbon Intensity Today (Half-Hourly)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: Placeholder(), // Replace with graph widget, e.g., fl_chart
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
