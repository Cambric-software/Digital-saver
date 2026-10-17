import 'package:url_launcher/url_launcher.dart';

/// Desktop and mobile have no way to write a file from the browser, so
/// the download is handed to the system browser instead.
void downloadFileImpl(String url, String filename) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
