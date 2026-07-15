import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/pin_service.dart';

/// Set a 4-digit PIN (entered twice) — shown once after first login.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _first = '';
  String _current = '';
  bool _confirming = false;
  String? _error;

  Future<void> _onDigit(String d) async {
    if (_current.length >= 4) return;
    setState(() {
      _current += d;
      _error = null;
    });

    if (_current.length == 4) {
      if (!_confirming) {
        setState(() {
          _first = _current;
          _current = '';
          _confirming = true;
        });
      } else if (_current == _first) {
        await context.read<PinService>().setPin(_current);
        // The gate in main.dart moves on automatically.
      } else {
        setState(() {
          _error = 'PINs did not match — start again.';
          _first = '';
          _current = '';
          _confirming = false;
        });
      }
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _PinPad(
          title: _confirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
          subtitle: _confirming
              ? 'Enter the same PIN again'
              : 'This PIN unlocks the app on this device',
          filled: _current.length,
          error: _error,
          onDigit: _onDigit,
          onBackspace: _onBackspace,
        ),
      ),
    );
  }
}

/// Unlock screen shown on cold start and after the background timeout.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _current = '';
  String? _error;
  int _attempts = 0;

  Future<void> _onDigit(String d) async {
    if (_current.length >= 4) return;
    setState(() {
      _current += d;
      _error = null;
    });

    if (_current.length == 4) {
      final ok = await context.read<PinService>().verifyPin(_current);
      if (!ok && mounted) {
        _attempts++;
        setState(() {
          _error = 'Incorrect PIN';
          _current = '';
        });
      }
      // On success the gate unlocks automatically.
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _signOutInstead() async {
    // Escape hatch for a forgotten PIN: sign out fully (clears PIN too) and
    // log in again with credentials.
    final auth = context.read<AuthService>();
    final pin = context.read<PinService>();
    await auth.logout();
    await pin.clearPin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _PinPad(
                title: 'Enter your PIN',
                subtitle: 'The app was locked for your security',
                filled: _current.length,
                error: _error,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ),
            if (_attempts >= 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: _signOutInstead,
                  child: const Text('Forgot PIN? Sign out and log in again'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shared dots + keypad UI.
class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.error,
  });

  final String title;
  final String subtitle;
  final int filled;
  final String? error;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 48, color: Colors.indigo),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final on = i < filled;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? Colors.indigo : Colors.transparent,
                border: Border.all(color: Colors.indigo, width: 2),
              ),
            );
          }),
        ),
        SizedBox(
          height: 28,
          child: error != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red)),
                )
              : null,
        ),
        const SizedBox(height: 8),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 88, height: 72);
              }
              final isBack = key == '<';
              return SizedBox(
                width: 88,
                height: 72,
                child: TextButton(
                  onPressed: isBack ? onBackspace : () => onDigit(key),
                  child: isBack
                      ? const Icon(Icons.backspace_outlined, size: 26)
                      : Text(key,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
