import 'dart:convert';
import 'package:http/http.dart' as http;

class CarbonIntensityService {
  final String baseUrl = 'https://api.carbonintensity.org.uk';

  // Fetch current national carbon intensity
  Future<Map<String, dynamic>> fetchCurrentIntensity() async {
    final response = await http.get(Uri.parse('$baseUrl/intensity'));

    if (response.statusCode == 200) {
      // Parse JSON response
      final data = json.decode(response.body);
      return data['data'][0]['intensity'];
    } else {
      throw Exception('Failed to load current intensity');
    }
  }

  // Fetch half-hourly carbon intensity for the day
  Future<List<dynamic>> fetchHalfHourlyIntensity() async {
    final response = await http.get(Uri.parse('$baseUrl/intensity/date'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load half-hourly intensity');
    }
  }
}
