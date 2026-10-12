import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registers a token obtained from the platform push provider.
/// Never call before explicit notification opt-in and OS permission.
class PushDeviceRegistration {
  const PushDeviceRegistration();

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Autenticação necessária.');
    if (platform != 'android' && platform != 'ios') {
      throw ArgumentError.value(platform, 'platform', 'Plataforma inválida');
    }
    if (token.length < 20 || token.length > 4096) {
      throw ArgumentError.value(token.length, 'token', 'Token inválido');
    }
    await Supabase.instance.client.from('user_push_devices').upsert({
      'user_id': user.id,
      'push_token': token,
      'platform': platform,
      'enabled': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,push_token');
  }

  Future<void> unregisterAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('user_push_devices')
        .delete()
        .eq('user_id', user.id);
  }

  static String? currentPlatform() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }
}
