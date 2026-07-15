import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screens.dart';
import 'services/auth_service.dart';
import 'services/offence_store.dart';
import 'services/pin_service.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final pin = PinService()..init();
  final auth = AuthService(pin: pin)..tryAutoLogin();
  final store = OffenceStore()..load();
  final sync = SyncService(auth: auth, store: store);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: pin),
      ],
      child: const PoliceApp(),
    ),
  );
}

class PoliceApp extends StatefulWidget {
  const PoliceApp({super.key});

  @override
  State<PoliceApp> createState() => _PoliceAppState();
}

class _PoliceAppState extends State<PoliceApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Track backgrounding so the PIN lock engages after the timeout.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pin = context.read<PinService>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pin.appBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      pin.appResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Police Crime System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // The gate, in order: not logged in -> Login; logged in without a PIN
      // -> set one (mandatory); locked -> unlock; otherwise -> Home.
      home: Consumer2<AuthService, PinService>(
        builder: (context, auth, pin, _) {
          if (!auth.isLoggedIn) return const LoginScreen();
          if (!pin.hasPin) return const PinSetupScreen();
          if (pin.locked) return const PinLockScreen();
          return const HomeScreen();
        },
      ),
    );
  }
}
