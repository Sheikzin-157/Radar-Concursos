import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/data/push_device_registration.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final enabled =
        const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;
    final user = enabled ? Supabase.instance.client.auth.currentUser : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user == null) ...[
            const Text('Entre na sua conta para acessar favoritos e preferências.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('Entrar ou criar conta'),
            ),
          ] else ...[
            Text(user.email ?? 'Conta autenticada',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.bookmarks_outlined),
              title: const Text('Meus favoritos'),
              onTap: () => context.push('/favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Preferências de concursos'),
              onTap: () => context.push('/preferences'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Meus alertas'),
              onTap: () => context.push('/alerts'),
            ),
            const Divider(),
            OutlinedButton(
              onPressed: _busy ? null : () async {
                setState(() => _busy = true);
                try {
                  await const PushDeviceRegistration().unregisterAll();
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/competitions');
                } catch (_) {
                  if (mounted) setState(() => _error = 'Não foi possível sair da conta.');
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
              child: const Text('Sair da conta'),
            ),
          ],
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}
