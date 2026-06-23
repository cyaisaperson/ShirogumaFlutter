class PainScale {
  const PainScale._();

  static const levels = [2, 4, 6, 8, 10];

  static int forNormalizedSas(int normalizedSas) {
    if (normalizedSas <= 0) return 0;
    if (normalizedSas <= 20) return 2;
    if (normalizedSas <= 36) return 4;
    if (normalizedSas <= 50) return 6;
    if (normalizedSas <= 70) return 8;
    return 10;
  }

  static int fromLegacyLevel(int painLevel) {
    return switch (painLevel) {
      1 => 2,
      2 => 4,
      3 => 6,
      4 => 8,
      5 => 10,
      _ => painLevel,
    };
  }

  static String? wongBakerAssetForLevel(int painLevel) {
    if (!levels.contains(painLevel)) {
      return null;
    }
    return 'assets/wong_baker/wong-baker-scale-$painLevel.jpg';
  }
}
