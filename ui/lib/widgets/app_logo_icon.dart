import 'package:flutter/material.dart';

class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    this.size = 36,
    this.borderRadius,
    super.key,
  });

  static const assetName = 'assets/branding/specmoa_icon.png';
  static const lockupAssetName = 'assets/branding/specmoa_logo.png';

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetName,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: image,
    );
  }
}

class AppLogoLockup extends StatelessWidget {
  const AppLogoLockup({
    this.width = 180,
    super.key,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppLogoIcon.lockupAssetName,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
