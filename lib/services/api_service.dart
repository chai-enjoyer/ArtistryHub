import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiKey = 'fa661c06a6f4c420ac2ea4ca26db5229';
  static const String baseUrl = 'http://ws.audioscrobbler.com/2.0/';

  Future<Map<String, dynamic>> searchArtist(String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?method=artist.search&artist=$artistName&api_key=$apiKey&format=json'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load artist data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}