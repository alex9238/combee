import 'package:flutter/cupertino.dart';

import 'app_routes.dart';

class RouteGenerator {
  static Route? onGenerate(RouteSettings settings) {
    final route = settings.name;

    switch (route) {
      case AppRoutes.login:
        return errorRoute();

      case AppRoutes.signup:
        return errorRoute();

      case AppRoutes.home:
        return errorRoute();

      default:
        return errorRoute();
    }
  }

  static Route? errorRoute() =>
      //CupertinoPageRoute(builder: (_) => const UnknownPage());
      CupertinoPageRoute(builder: (_) => Container());
}
