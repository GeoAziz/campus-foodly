import 'package:flutter/material.dart';

import 'constants.dart';

ThemeData buildLightThemeData() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    fontFamily: "SF Pro Text",
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    inputDecorationTheme: inputDecorationTheme,
    buttonTheme: buttonThemeData,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

ThemeData buildDarkThemeData() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    colorScheme: colorScheme,
    primaryColor: colorScheme.primary,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    fontFamily: "SF Pro Text",
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),
    inputDecorationTheme: inputDecorationTheme,
    buttonTheme: buttonThemeData,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  fillColor: inputColor,
  filled: true,
  // hintStyle: Theme.of(context).textTheme.bodyMedium,
  contentPadding: const EdgeInsets.all(defaultPadding),
  border: kDefaultOutlineInputBorder,
  enabledBorder: kDefaultOutlineInputBorder,
  focusedBorder: kDefaultOutlineInputBorder.copyWith(
      borderSide: BorderSide(
    color: primaryColor.withValues(alpha: 0.5),
  )),
  errorBorder: kDefaultOutlineInputBorder.copyWith(
    borderSide: kErrorBorderSide,
  ),
  focusedErrorBorder: kDefaultOutlineInputBorder.copyWith(
    borderSide: kErrorBorderSide,
  ),
);

const ButtonThemeData buttonThemeData = ButtonThemeData(
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8))),
);
