import 'package:flutter/material.dart';

import 'routes.dart';

class UniConnectApp extends StatelessWidget {
  const UniConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniConnect',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.register,
      routes: AppRoutes.routes,
    );
  }
}