import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _authenticate({bool createAccount = false}) async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _message = 'Informe email e senha.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (createAccount) {
        await Supabase.instance.client.auth.signUp(email: email, password: _password.text);
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: _password.text);
      }
      if (!mounted) return;
      setState(() => _message = createAccount ? 'Cadastro enviado. Confirme seu email, se solicitado.' : 'Sessão iniciada com sucesso.');
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Informe seu email para recuperar a senha.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) setState(() => _message = 'Se o email estiver cadastrado, receberá instruções para recuperação.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível solicitar recuperação.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured =
        const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
        const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Acesse sua conta', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            if (!configured)
              const Text('Autenticação indisponível: configure SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY no ambiente.'),
            if (configured) ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Senha'),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _authenticate(),
                child: Text(_busy ? 'Aguarde...' : 'Entrar'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _authenticate(createAccount: true),
                child: const Text('Criar conta'),
              ),
              TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
