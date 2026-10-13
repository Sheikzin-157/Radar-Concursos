import 'package:flutter/material.dart';

import '../design_system/theme/radar_theme.dart';
import 'router/app_router.dart';

class RadarConcursosApp extends StatelessWidget {
  const RadarConcursosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Radar Concursos',
      debugShowCheckedModeBanner: false,
      theme: RadarTheme.light(),
      routerConfig: appRouter,
    );
  }
}
