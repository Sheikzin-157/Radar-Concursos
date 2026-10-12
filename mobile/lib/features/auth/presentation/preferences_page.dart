import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/data/push_device_registration.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final _state = TextEditingController();
  bool _notify = false;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  User? get _user =>
      const String.fromEnvironment('SUPABASE_URL').isEmpty ||
              const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isEmpty
          ? null
          : Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final records = await Supabase.instance.client
          .from('user_competition_preferences')
          .select('preferred_state, notify_updates')
          .eq('user_id', user.id)
          .limit(1);
      if (mounted && records.isNotEmpty) {
        _state.text = (records.first['preferred_state'] as String?) ?? '';
        setState(() => _notify = records.first['notify_updates'] == true);
      }
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível carregar suas preferências.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null || _saving) return;
    final uf = _state.text.trim().toUpperCase();
    const validStates = {
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
      'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
      'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
    };
    if (uf.isNotEmpty && !validStates.contains(uf)) {
      setState(() => _message = 'Informe uma UF válida, como CE ou SP.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.from('user_competition_preferences').upsert({
        'user_id': user.id,
        'preferred_state': uf.isEmpty ? null : uf,
        'notify_updates': _notify,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (!_notify) {
        await const PushDeviceRegistration().unregisterAll();
      }
      if (mounted) setState(() => _message = 'Preferências salvas.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível salvar as preferências.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preferências')),
        body: Center(
          child: TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Entre para configurar suas preferências'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Preferências')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Personalizar acompanhamento', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: _state,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 2,
                  decoration: const InputDecoration(
                    labelText: 'UF de preferência',
                    hintText: 'Ex.: CE (vazio para todas)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  value: _notify,
                  onChanged: (value) => setState(() => _notify = value),
                  title: const Text('Desejo receber alertas de atualizações'),
                  subtitle: const Text('Preferência registrada; o envio automático será habilitado em etapa posterior.'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvando...' : 'Salvar preferências'),
                ),
                if (_message != null) Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!),
                ),
              ],
            ),
    );
  }
}
