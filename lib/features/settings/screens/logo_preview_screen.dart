import 'package:material_ui/material_ui.dart';

import '../widgets/islamic_logo_widget.dart';

class LogoPreviewScreen extends StatelessWidget {
  const LogoPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: IslamicAppLogo(size: 240),
        ),
      ),
    );
  }
}
