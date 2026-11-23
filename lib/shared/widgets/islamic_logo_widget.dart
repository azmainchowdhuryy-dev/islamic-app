import 'package:material_ui/material_ui.dart';

/// The approved Islamic App logo, shared by the in-app brand and launcher.
class IslamicAppLogo extends StatelessWidget {
  final double size;

  const IslamicAppLogo({
    super.key,
    this.size = 220,
  }) : assert(size > 0);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Islamic App logo',
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Image.asset(
            'assets/images/islamic_app_logo.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
