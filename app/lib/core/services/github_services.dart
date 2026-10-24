/// Looks up the newest published release of Digital Saver.
///
/// This used to return a hardcoded `'v1.0.3-beta'` whenever the request failed,
/// so an offline app stated a version that had never been published, and built
/// download links from it that 404'd. A version nobody can verify is worse than
/// no version shown at all, so failure is now reported as failure.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads release information from the public GitHub API.
class GithubService {
  /// Create the service.
  const GithubService();

  /// The tag of the newest published release, or null if it cannot be read.
  ///
  /// Null covers being offline, rate-limited, and a release list that is empty.
  /// Callers must show nothing rather than substituting a guess.
  Future<String?> fetchLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/Cambric-software/Digital-saver/releases/latest',
        ),
        headers: <String, String>{
          'Accept': 'application/vnd.github+json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final tag = decoded['tag_name'];
      if (tag is! String || tag.trim().isEmpty) return null;
      return tag.trim();
    } catch (_) {
      // Offline, blocked, timed out or malformed. There is nothing honest to
      // report, so report nothing.
      return null;
    }
  }
}
