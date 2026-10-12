import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/competitions/presentation/competition_detail_page.dart';
import '../../features/competitions/presentation/competition_list_page.dart';

final appRouter = GoRouter(
  initialLocation: '/competitions',
  routes: [
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
