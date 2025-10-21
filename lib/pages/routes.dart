import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'register_page.dart';
import 'reset_password_page.dart';
import 'messages_page.dart';
import 'settings_page.dart';
import 'settings_profile_form.dart';
import 'privacy_page.dart';
import 'about_page.dart';

class Routes {
  static const String login = '/';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String messages = '/messages';
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return MaterialPageRoute(builder: (context) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (context) => RegisterPage());
      case resetPassword:
        return MaterialPageRoute(builder: (context) => ResetPasswordPage());
      case home:
        return MaterialPageRoute(builder: (context) => const HomePage());
      case profile:
        return MaterialPageRoute(builder: (context) => ProfilePage());
      case messages:
        return MaterialPageRoute(builder: (context) => const MessagesPage());
      case settings:
        return MaterialPageRoute(builder: (context) => const SettingsPage());
      case settingsProfile:
        return MaterialPageRoute(builder: (context) => const SettingsProfileForm());
      case privacy:
        return MaterialPageRoute(builder: (context) => const PrivacyPage());
      case about:
        return MaterialPageRoute(builder: (context) => const AboutPage());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${routeSettings.name}')),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => LoginPage(),
      register: (context) => RegisterPage(),
      resetPassword: (context) => ResetPasswordPage(),
      home: (context) => const HomePage(),
      profile: (context) => ProfilePage(),
      messages: (context) => const MessagesPage(),
      settings: (context) => const SettingsPage(),
      settingsProfile: (context) => const SettingsProfileForm(),
      privacy: (context) => const PrivacyPage(),
      about: (context) => const AboutPage(),
    };
  }
}