import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final sourcePath = 'assets/logo.jpg';
  
  // Read source image
  final sourceFile = File(sourcePath);
  final sourceBytes = await sourceFile.readAsBytes();
  final source = img.decodeImage(sourceBytes);
  
  if (source == null) {
    print('Failed to decode source image');
    return;
  }
  
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
  final maskable = img.copyResize(source, width: 512, height: 512);
  await File('web/icons/Icon-maskable-192.png').writeAsBytes(img.encodePng(maskable));
  await File('web/icons/Icon-maskable-512.png').writeAsBytes(img.encodePng(maskable));
  print('Created: web/icons/Icon-maskable-192.png');
  print('Created: web/icons/Icon-maskable-512.png');
  
  print('\nDone! All icons generated.');
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
