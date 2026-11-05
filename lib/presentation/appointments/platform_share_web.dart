import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadBytesOnWeb(Uint8List bytes, String fileName) async {
  final jsBytes = bytes.toJS;
  final file = web.File([jsBytes].toJS, fileName, web.FilePropertyBag(type: 'image/png'));

  // Try native Web Share API with file (Chrome Android 76+, Safari iOS 15+).
  try {
    final shareData = web.ShareData(
      files: [file].toJS,
      title: 'Detalle de turno',
    );
    if (web.window.navigator.canShare(shareData)) {
      await web.window.navigator.share(shareData).toDart;
      return;
    }
  } catch (_) {
    // User cancelled or share not supported — fall through to download.
  }

  // Fallback: trigger browser download.
  final blob = web.Blob([jsBytes].toJS, web.BlobPropertyBag(type: 'image/png'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
