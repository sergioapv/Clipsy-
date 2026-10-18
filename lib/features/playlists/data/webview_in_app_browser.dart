import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../domain/in_app_browser.dart';
import '../domain/youtube_browse_policy.dart';

/// [InAppBrowser] on top of the platform web view, restricted to YouTube.
class WebViewInAppBrowser implements InAppBrowser {
  WebViewInAppBrowser() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              YouTubeBrowsePolicy.allows(Uri.tryParse(request.url))
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          // YouTube is a single-page app: most navigation only changes the
          // URL via the history API, which arrives here rather than as a
          // page load.
          onUrlChange: (change) => _setUrl(change.url),
          onPageStarted: _setUrl,
          onProgress: (p) => _progress.value = p,
        ),
      );
  }

  late final WebViewController _controller;
  final _url = ValueNotifier<Uri?>(null);
  final _progress = ValueNotifier<int>(0);

  void _setUrl(String? url) {
    if (url != null) _url.value = Uri.tryParse(url);
  }

  @override
  ValueListenable<Uri?> get url => _url;

  @override
  ValueListenable<int> get progress => _progress;

  @override
  Widget buildView(BuildContext context) =>
      WebViewWidget(controller: _controller);

  @override
  Future<void> load(Uri uri) => _controller.loadRequest(uri);

  @override
  Future<bool> canGoBack() => _controller.canGoBack();

  @override
  Future<void> goBack() => _controller.goBack();

  @override
  Future<void> dispose() async {
    // Stop any playing video; the platform view is torn down with the widget.
    unawaited(
      _controller
          .runJavaScript(
            "document.querySelectorAll('video').forEach(v => v.pause());",
          )
          .catchError((Object _) {}),
    );
    _url.dispose();
    _progress.dispose();
  }
}
