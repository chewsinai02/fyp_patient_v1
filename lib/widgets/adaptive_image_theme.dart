import 'package:flutter/material.dart';

class AdaptiveImageTheme extends ThemeExtension<AdaptiveImageTheme> {
  final String defaultFallbackAsset;
  final Color defaultLoadingColor;

  const AdaptiveImageTheme({
    required this.defaultFallbackAsset,
    required this.defaultLoadingColor,
  });

  @override
  ThemeExtension<AdaptiveImageTheme> copyWith({
    String? defaultFallbackAsset,
    Color? defaultLoadingColor,
  }) {
    return AdaptiveImageTheme(
      defaultFallbackAsset: defaultFallbackAsset ?? this.defaultFallbackAsset,
      defaultLoadingColor: defaultLoadingColor ?? this.defaultLoadingColor,
    );
  }

  @override
  ThemeExtension<AdaptiveImageTheme> lerp(
    ThemeExtension<AdaptiveImageTheme>? other,
    double t,
  ) {
    if (other is! AdaptiveImageTheme) {
      return this;
    }
    return AdaptiveImageTheme(
      defaultFallbackAsset: other.defaultFallbackAsset,
      defaultLoadingColor: Color.lerp(
            defaultLoadingColor,
            other.defaultLoadingColor,
            t,
          ) ??
          defaultLoadingColor,
    );
  }
}
