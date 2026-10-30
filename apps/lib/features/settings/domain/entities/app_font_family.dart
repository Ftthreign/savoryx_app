/// 6 official typography options supported across Savoryx OS.
enum AppFontFamily {
  nunitoSans,
  inter,
  poppins,
  ubuntu,
  changaOne,
  tiny5;

  String get displayName {
    switch (this) {
      case AppFontFamily.nunitoSans:
        return 'Nunito Sans';
      case AppFontFamily.inter:
        return 'Inter';
      case AppFontFamily.poppins:
        return 'Poppins';
      case AppFontFamily.ubuntu:
        return 'Ubuntu';
      case AppFontFamily.changaOne:
        return 'Changa One';
      case AppFontFamily.tiny5:
        return 'Tiny5';
    }
  }

  String get description {
    switch (this) {
      case AppFontFamily.nunitoSans:
        return 'Tactile Clay Friendly (Default)';
      case AppFontFamily.inter:
        return 'High Financial Readability';
      case AppFontFamily.poppins:
        return 'Modern Geometric Clean';
      case AppFontFamily.ubuntu:
        return 'Fluid Curved Character';
      case AppFontFamily.changaOne:
        return 'Ultra-Bold Chunky Display';
      case AppFontFamily.tiny5:
        return '16-bit Retro Pixel Gaming';
    }
  }
}
