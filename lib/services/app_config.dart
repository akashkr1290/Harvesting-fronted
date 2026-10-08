/// Build-time settings: flutter build ... --dart-define=HELPLINE_NUMBER=18001234567
class AppConfig {
  /// Phone number of the FPO / support desk shown on every Simple-mode screen. Empty hides the button.
  static const String helplineNumber = String.fromEnvironment('HELPLINE_NUMBER');
}
