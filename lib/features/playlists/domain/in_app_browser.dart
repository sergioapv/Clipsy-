import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Thin seam over the web view used by the YouTube browser, so the screen can
/// be tested without a real web view.
abstract interface class InAppBrowser {
  /// The current page URL, including in-page (history API) navigation.
  ValueListenable<Uri?> get url;

  /// Page load progress, 0–100.
  ValueListenable<int> get progress;

  Widget buildView(BuildContext context);
  Future<void> load(Uri uri);
  Future<bool> canGoBack();
  Future<void> goBack();
  Future<void> dispose();
}
