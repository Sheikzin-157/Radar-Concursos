import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/profile_page.dart';
import '../../features/auth/presentation/preferences_page.dart';
import '../../features/competitions/presentation/favorites_page.dart';
import '../../features/competitions/presentation/calendar_page.dart';
import '../../features/competitions/presentation/competition_detail_page.dart';
import '../../features/competitions/presentation/competition_list_page.dart';

final appRouter = GoRouter(
  initialLocation: '/competitions',
  routes: [
    GoRoute(path: '/calendar', builder: (_, _) => const CalendarPage()),
    GoRoute(path: '/preferences', builder: (_, _) => const PreferencesPage()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      redirect: (_, _) => '/competitions',
    ),
    GoRoute(
      path: '/competitions',
      builder: (context, state) => const CompetitionListPage(),
      routes: [
        GoRoute(
          path: ':competitionId',
          builder: (context, state) => CompetitionDetailPage(
            competitionId: state.pathParameters['competitionId']!,
          ),
        ),
      ],
    ),
  ],
);
