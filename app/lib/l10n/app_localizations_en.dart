// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crescent Gate';

  @override
  String get loginButton => 'Login';

  @override
  String get welcomeMessage => 'Welcome Back!';

  @override
  String get visitorRequest => 'Visitor Request';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';
}
