import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Use cambric-icon.png as the source (high resolution)
  final sourcePath = 'assets/cambric-icon.png';
  
  // Read source image
  final sourceFile = File(sourcePath);
  final sourceBytes = await sourceFile.readAsBytes();
  final source = img.decodeImage(sourceBytes);
  
  if (source == null) {
    print('Failed to decode source image');
    return;
  }
  
  print('Source image: ${source.width}x${source.height}');
  
  // Copy to all Android density folders
  for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
    final resized = img.copyResize(source, width: _getAndroidSize(density), height: _getAndroidSize(density));
    await File('android/app/src/main/res/mipmap-$density/ic_launcher.png').writeAsBytes(img.encodePng(resized));
    print('Created: android/app/src/main/res/mipmap-$density/ic_launcher.png');
  }
  
  // Generate iOS icons
  final iosSizes = [20, 29, 40, 60, 76, 83, 1024];
  for (final size in iosSizes) {
    final resized = img.copyResize(source, width: size, height: size);
    final outputPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-${size}x$size.png';
    await File(outputPath).writeAsBytes(img.encodePng(resized));
    print('Created: $outputPath');
  }
  
  // Generate web icons
  for (final size in [192, 512]) {
    final resized = img.copyResize(source, width: size, height: size);
    await File('web/icons/Icon-$size.png').writeAsBytes(img.encodePng(resized));
    print('Created: web/icons/Icon-$size.png');
  }
  
  // Maskable icons for web
  for (final size in [192, 512]) {
    final resized = img.copyResize(source, width: size, height: size);
    await File('web/icons/Icon-maskable-$size.png').writeAsBytes(img.encodePng(resized));
    print('Created: web/icons/Icon-maskable-$size.png');
  }
  
  // Also create favicon
  final favicon = img.copyResize(source, width: 32, height: 32);
  await File('web/favicon.png').writeAsBytes(img.encodePng(favicon));
  print('Created: web/favicon.png');
  
  print('\nDone! All icons generated from cambric-icon.png');
}

int _getAndroidSize(String density) {
  switch (density) {
    case 'mdpi': return 48;
    case 'hdpi': return 72;
    case 'xhdpi': return 96;
    case 'xxhdpi': return 144;
    case 'xxxhdpi': return 192;
    default: return 48;
  }
}
