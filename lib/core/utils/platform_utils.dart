import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class to determine platform types with strict mobile isolation.
class PlatformUtils {
  /// Returns true only on Android and iOS mobile operating systems.
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Returns true on all non-mobile operating systems (macOS, Windows, Linux, and Web).
  static bool get isDesktopOrWeb => !isMobile;
}
