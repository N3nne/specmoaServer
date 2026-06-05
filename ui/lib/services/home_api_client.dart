import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/home_data.dart';

class HomeApiClient {
  const HomeApiClient({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<HomeData> fetchHome({String? userId}) async {
    final client = _client ?? http.Client();

    try {
      final response = await client.get(
        Uri.parse('${AppConfig.apiBaseUrl}/home'),
        headers: {
          if (userId != null && userId.isNotEmpty) 'x-user-id': userId,
        },
      ).timeout(AppConfig.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Home API failed with ${response.statusCode}');
      }

      return HomeData.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }
}
