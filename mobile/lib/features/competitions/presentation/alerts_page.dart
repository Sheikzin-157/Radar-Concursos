import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  Future<List<Map<String, dynamic>>>? _alerts;

  bool get _configured =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    if (!_configured || Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    _alerts = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final value = await Supabase.instance.client.rpc('my_upcoming_competition_alerts');
    if (value is! List) throw const FormatException('Resposta de alertas inválida.');
    return value.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _configured && Supabase.instance.client.auth.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus alertas')),
      body: !signedIn
          ? Center(child: TextButton(
              onPressed: () => context.push('/login'),
              child: const Text('Entre para visualizar alertas'),
            ))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _alerts,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Não foi possível carregar os alertas. Tentar novamente'),
                  ));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Nenhum evento correspondente aos seus interesses nos próximos 14 dias.'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.push('/preferences'),
                          child: const Text('Configurar preferências'),
                        ),
                      ],
                    ),
                  ));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _alerts;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final date = DateTime.parse(item['starts_at'] as String).toLocal();
                      return ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(item['event_title'] as String),
                        subtitle: Text(
                          '${item['competition_title']} — ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/competitions/${item['competition_id']}'),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
