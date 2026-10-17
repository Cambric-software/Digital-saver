// Web-only download shim, reached through a conditional import so that
// desktop and mobile builds never compile it. dart:html is the correct
// tool here and these two lints cannot see that.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void downloadFileImpl(String url, String filename) {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
