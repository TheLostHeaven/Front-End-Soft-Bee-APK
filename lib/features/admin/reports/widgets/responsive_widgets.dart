import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktop;
}

class ApiarioTheme {
  static const Color primaryColor = Color(0xFF8D6E63);
  static const Color secondaryColor = Color(0xFFFFA000);
  static const Color backgroundColor = Color(0xFFFFF8E1);
  static const Color cardColor = Color(0xFFFFECB3);
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color dangerColor = Colors.red;

  static TextStyle get titleStyle => TextStyle(
    fontFamily: 'Roboto',
    color: primaryColor,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodyStyle => TextStyle(fontFamily: 'Roboto');

  // Responsive padding
  static double getPadding(BuildContext context) {
    if (ResponsiveBreakpoints.isLargeDesktop(context)) return 32.0;
    if (ResponsiveBreakpoints.isDesktop(context)) return 24.0;
    if (ResponsiveBreakpoints.isTablet(context)) return 20.0;
    return 16.0;
  }

  // Responsive font sizes
  static double getTitleFontSize(BuildContext context) {
    if (ResponsiveBreakpoints.isLargeDesktop(context)) return 32.0;
    if (ResponsiveBreakpoints.isDesktop(context)) return 28.0;
    if (ResponsiveBreakpoints.isTablet(context)) return 26.0;
    return 24.0;
  }

  static double getSubtitleFontSize(BuildContext context) {
    if (ResponsiveBreakpoints.isLargeDesktop(context)) return 24.0;
    if (ResponsiveBreakpoints.isDesktop(context)) return 22.0;
    if (ResponsiveBreakpoints.isTablet(context)) return 20.0;
    return 18.0;
  }

  static double getBodyFontSize(BuildContext context) {
    if (ResponsiveBreakpoints.isLargeDesktop(context)) return 18.0;
    if (ResponsiveBreakpoints.isDesktop(context)) return 16.0;
    if (ResponsiveBreakpoints.isTablet(context)) return 15.0;
    return 14.0;
  }
}
