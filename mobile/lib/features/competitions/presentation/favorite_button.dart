import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({required this.competitionId, super.key});
  final String competitionId;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _configured =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;

  User? get _user => _configured
      ? Supabase.instance.client.auth.currentUser
      : null;

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
      final rows = await Supabase.instance.client
          .from('competition_favorites')
          .select('competition_id')
          .eq('user_id', user.id)
          .eq('competition_id', widget.competitionId)
          .limit(1);
      if (mounted) {
        setState(() {
          _isFavorite = rows.isNotEmpty;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar os favoritos.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    final user = _user;
    if (user == null) {
      context.push('/login');
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final table = Supabase.instance.client.from('competition_favorites');
      if (_isFavorite) {
        await table
            .delete()
            .eq('user_id', user.id)
            .eq('competition_id', widget.competitionId);
      } else {
        await table.insert({
          'user_id': user.id,
          'competition_id': widget.competitionId,
        });
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível atualizar o favorito.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_configured) {
      return const Text('Favoritos disponíveis quando a conta estiver configurada.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _saving || _loading ? null : _toggle,
          icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
          label: Text(_user == null
              ? 'Entrar para salvar concurso'
              : _isFavorite
                  ? 'Remover dos favoritos'
                  : 'Salvar nos favoritos'),
        ),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextButton(onPressed: _load, child: const Text('Tentar novamente')),
        ],
      ],
    );
  }
}
