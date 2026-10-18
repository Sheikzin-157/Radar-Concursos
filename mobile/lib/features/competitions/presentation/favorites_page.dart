import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/competition_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<List<Map<String, dynamic>>>? _favorites;

  bool get _configured =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;

  User? get _user =>
      _configured ? Supabase.instance.client.auth.currentUser : null;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final user = _user;
    if (user == null) return;
    _favorites = Supabase.instance.client
        .from('competition_favorites')
        .select('competition_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus favoritos')),
      body: user == null
          ? Center(
              child: TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Entre para visualizar seus favoritos'),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _favorites,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(_refresh),
                      child: const Text('Erro ao carregar. Tentar novamente'),
                    ),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('Você ainda não salvou concursos.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_refresh);
                    await _favorites;
                  },
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final id = rows[index]['competition_id'] as String;
                      return _FavoriteCompetitionTile(competitionId: id);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _FavoriteCompetitionTile extends ConsumerWidget {
  const _FavoriteCompetitionTile({required this.competitionId});

  final String competitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competition = ref.watch(competitionDetailProvider(competitionId));
    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text(competition.maybeWhen(
        data: (item) => item.title,
        orElse: () => 'Concurso salvo',
      )),
      subtitle: Text(competition.maybeWhen(
        data: (item) => item.organization.officialName,
        orElse: () => 'Toque para consultar detalhes',
      )),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/competitions/$competitionId'),
    );
  }
}
