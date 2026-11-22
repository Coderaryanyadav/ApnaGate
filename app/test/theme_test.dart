import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/utils/app_theme.dart';

void main() {
  test('AppTheme darkTheme configuration tests', () {
    final theme = AppTheme.darkTheme;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppTheme.darkBackground);
    expect(theme.colorScheme.primary, AppTheme.primaryColor);
    expect(theme.colorScheme.secondary, AppTheme.accentColor);
    expect(theme.colorScheme.error, AppTheme.dangerColor);
  });

  test('AppTheme lightTheme configuration tests', () {
    final theme = AppTheme.lightTheme;

    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppTheme.primaryColor);
  });
}
