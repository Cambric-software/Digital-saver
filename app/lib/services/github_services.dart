import 'dart:convert';
import 'package:http/http.dart' as http;

class GithubService {
  Future<String> fetchLatestVersion() async {
    final response = await http.get(
      Uri.parse("https://api.github.com/repos/Cambric-software/Digital-saver/releases"),
    );

    if (response.statusCode == 200) {
      final releases = jsonDecode(response.body);
      // Grab the first release (most recent, even if prerelease)
      return releases.first['tag_name']; // e.g. "v1.0.2-beta"
    } else {
      throw Exception("Failed to fetch release info");
    }
  }
}
