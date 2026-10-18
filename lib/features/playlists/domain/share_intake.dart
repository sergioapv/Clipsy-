/// Links shared to Clipsy from other apps ("Share to Clipsy").
abstract interface class ShareIntake {
  /// Shared texts, including one that launched the app.
  Stream<String> get shares;
}
