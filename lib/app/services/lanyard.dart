import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snooper/app/screens/home.dart';

import '../models/lanyard_user.dart';

class LanyardService {
  static const String _apiBaseUrl = 'https://api.lanyard.rest/v1';

  static final LanyardService _instance = LanyardService._internal();
  factory LanyardService() => _instance;
  LanyardService._internal();

  Future<LanyardUser?> getUserByRest(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/users/$userId'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          return LanyardUser.fromJson(jsonData['data']);
        }
      }
      return null;
    } catch (e) {
      logger.e('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<LanyardUser>> getUsersByRest(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    List<LanyardUser> users = [];

    for (final userId in userIds) {
      try {
        final user = await getUserByRest(userId);
        if (user != null) {
          users.add(user);
        }
      } catch (e) {
        logger.e('Error fetching data for user $userId: $e');
      }
    }

    return users;
  }
}
