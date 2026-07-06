import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Stateless: it just displays who is logged in and a logout button. All the
/// changing data lives in AuthService, which it reads.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            Text('Signed in as ${user?.name ?? 'Officer'}',
                style: Theme.of(context).textTheme.titleMedium),
            if (user?.serviceNumber != null)
              Text('Service no: ${user!.serviceNumber}'),
            if ((user?.roles ?? []).isNotEmpty)
              Text('Roles: ${user!.roles.join(', ')}'),
            const SizedBox(height: 24),
            const Text('Offence capture coming next…'),
          ],
        ),
      ),
    );
  }
}
