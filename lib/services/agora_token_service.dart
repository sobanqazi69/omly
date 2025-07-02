import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:live_13/utils/debug.dart';

// ✅ Replace this with your actual Railway domain
const String railwayFunctionUrl =
    'https://steadfast-vibrancy-production.up.railway.app/token';

Future<String?> fetchAgoraToken({
  required String channelName,
  required int uid,
}) async {
  try {
    debug('=== AGORA TOKEN GENERATION ===');
    debug('Channel Name: $channelName');
    debug('UID: $uid');
    debug('Function URL: $railwayFunctionUrl');

    final requestBody = {
      'channelName': channelName,
      'uid': uid,
      'expireTime': 3600,
    };

    debug('Request Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse(railwayFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    debug('Response Status Code: ${response.statusCode}');
    debug('Response Headers: ${response.headers}');
    debug('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debug('Parsed Response Data: $data');

      final token = data['token'] as String?;
      debug('Extracted Token: $token');
      debug('Token Length: ${token?.length}');

      if (token == null || token.isEmpty) {
        debug('ERROR: Token is null or empty!');
        return null;
      }

      debug('Token Generation SUCCESS ✅');
      return token;
    } else {
      debug('ERROR: HTTP ${response.statusCode}');
      debug('Error Body: ${response.body}');

      try {
        final errorData = jsonDecode(response.body);
        debug('Parsed Error: $errorData');
      } catch (e) {
        debug('Could not parse error response: $e');
      }
    }
  } catch (e) {
    debug('EXCEPTION in fetchAgoraToken: $e');
    debug('Exception Type: ${e.runtimeType}');
  }

  debug('Token Generation FAILED ❌');
  return null;
} 