import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/volunteer/screens/volunteer_intro_screen.dart';
import '../features/volunteer/screens/volunteer_verification_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/contacts/screens/contacts_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/sos/screens/sos_screen.dart';
import '../features/safe_route/screens/safe_route_screen.dart';
import '../features/fake_call/screens/fake_call_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case AppRoutes.roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      
      case AppRoutes.volunteerIntro:
        return MaterialPageRoute(builder: (_) => const VolunteerIntroScreen());
      
      case AppRoutes.volunteerVerification:
        return MaterialPageRoute(builder: (_) => const VolunteerVerificationScreen());
      
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case AppRoutes.contacts:
        return MaterialPageRoute(builder: (_) => const ContactsScreen(isStandalone: true));
      
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen(isStandalone: true));
      
      case AppRoutes.sos:
        return MaterialPageRoute(builder: (_) => const SosScreen());
      
      case AppRoutes.safeRoute:
        return MaterialPageRoute(builder: (_) => const SafeRouteScreen());
      
      case AppRoutes.fakeCall:
        return MaterialPageRoute(builder: (_) => const FakeCallScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}