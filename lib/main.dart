import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'presentation/theme/app_theme.dart';
import 'router/app_router.dart';

const bool useEmulator = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulator) {
    const host = kIsWeb ? 'localhost' : '10.0.2.2';
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  runApp(const ProviderScope(child: ColibrApp()));
}

class ColibrApp extends ConsumerWidget {
  const ColibrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Colibrí',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
