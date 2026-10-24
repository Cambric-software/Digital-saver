import 'download_stub.dart'
    if (dart.library.html) 'download_web.dart';

void downloadFile(String url, String filename) {
  downloadFileImpl(url, filename);
}
