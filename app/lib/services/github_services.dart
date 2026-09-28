import 'dart:convert';
import 'package:http/http.dart' as http;

class GithubService {
  Future<String> fetchLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.github.com/repos/Cambric-software/Digital-saver/releases"),
        headers: {
          'User-Agent': 'Digital-Saver-App/1.0.3',
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> releases = jsonDecode(response.body);
        if (releases.isNotEmpty) {
          return releases.first['tag_name'] as String? ?? 'v1.0.3-beta';
        }
      }
      return 'v1.0.3-beta';
    } catch (_) {
      return 'v1.0.3-beta';
    }
  }
}
