import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_device_registration.dart';

/// Firebase initializes only when a project is configured and the user
/// explicitly enables push. No permission prompt happens during app startup.
class FirebasePushService {
  FirebasePushService();

  StreamSubscription<String>? _tokenSubscription;

  static bool get configured =>
      const String.fromEnvironment('FIREBASE_API_KEY').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_APP_ID').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_SENDER_ID').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_PROJECT_ID').isNotEmpty;

  Future<void> enable() async {
    if (kIsWeb) throw StateError('Push para web não está habilitado.');
    final platform = PushDeviceRegistration.currentPlatform();
    if (platform == null) throw StateError('Plataforma não suportada.');
    if (!configured) throw StateError('Firebase não configurado neste aplicativo.');
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Entre na conta antes de ativar o push.');

    final consent = await Supabase.instance.client
        .from('user_competition_preferences')
        .select('notify_updates')
        .eq('user_id', user.id)
        .limit(1);
    if (consent.isEmpty || consent.first['notify_updates'] != true) {
      throw StateError('Ative primeiro os alertas nas preferências.');
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        ),
      );
    }

    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      throw StateError('Permissão de notificações não concedida.');
    }

    if (platform == 'ios' && await messaging.getAPNSToken() == null) {
      throw StateError('O token APNs ainda não está disponível. Tente novamente.');
    }

    final token = await messaging.getToken();
    if (token == null) throw StateError('Não foi possível obter o token Firebase.');
    await const PushDeviceRegistration().register(token: token, platform: platform);
    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
      unawaited(_saveRefreshedToken(newToken, platform));
    });
  }

  Future<void> _saveRefreshedToken(String token, String platform) async {
    try {
      await const PushDeviceRegistration().register(token: token, platform: platform);
    } catch (error) {
      debugPrint('Não foi possível atualizar o token de notificações: $error');
    }
  }

  Future<void> disable() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await const PushDeviceRegistration().unregisterAll();
    if (Firebase.apps.isNotEmpty) {
      await FirebaseMessaging.instance.deleteToken();
    }
  }
}
