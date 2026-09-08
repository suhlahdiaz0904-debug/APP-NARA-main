import 'package:flutter/material.dart';

extension ExtendedNavigator on BuildContext {
  Future<dynamic> push(Widget page, {String? name}) async {
    return Navigator.push(
      this,
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
    );
  }

  Future<dynamic> pushReplacement(Widget page, {String? name}) async {
    return Navigator.pushReplacement(
      this,
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
    );
  }

  Future<dynamic> pushNamed(String routeName, {Object? arguments}) async {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  // Future<dynamic> pushReplacementNamed(String newRouteName,
  //     {Object? arguments}) {
  //   Navigator.popUntil(this, ModalRoute.withName(newRouteName));
  //   return Navigator.pushNamed(this, newRouteName, arguments: arguments);
  // }
  Future<dynamic> pushReplacementNamed(
    String newRouteName, {
    Object? arguments,
  }) {
    return Navigator.of(
      this,
    ).pushReplacementNamed(newRouteName, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    Navigator.pushNamedAndRemoveUntil(
      this,
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }

  Future<dynamic> pushAndRemoveAll(Widget page, {String? name}) async {
    return Navigator.pushAndRemoveUntil(
      this,
      MaterialPageRoute(
        builder: (_) => page,
        settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      ),
      (route) => false,
    );
  }

  void pop([dynamic result]) {
    Navigator.of(this).pop(result);
  }
}
