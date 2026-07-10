import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _titleCase(String raw) =>
      raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          // Header: avatar + name + rank
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    (user?.name ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Officer',
                    style: Theme.of(context).textTheme.headlineSmall),
                if (user?.rank != null)
                  Text(user!.rank!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Details
          _DetailTile(
            icon: Icons.badge,
            label: 'Service number',
            value: user?.serviceNumber ?? '—',
          ),
          _DetailTile(
            icon: Icons.local_police,
            label: 'Station',
            value: user?.station ?? '—',
          ),
          _DetailTile(
            icon: Icons.email,
            label: 'Email',
            value: user?.email ?? '—',
          ),
          _DetailTile(
            icon: Icons.verified_user,
            label: 'Roles',
            value: (user?.roles ?? [])
                    .map(_titleCase)
                    .join(', ')
                    .ifEmptyThen('—'),
          ),
          FutureBuilder<int>(
            future: DatabaseService.instance.watchlistCount(),
            builder: (context, snap) => _DetailTile(
              icon: Icons.flag,
              label: 'Watchlist cached',
              value: snap.hasData ? '${snap.data} vehicles' : '…',
            ),
          ),

          const Divider(),
          const SizedBox(height: 24),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () {
                  // Pop the profile screen first, then log out; the auth gate
                  // returns to the login screen automatically.
                  Navigator.of(context).pop();
                  context.read<AuthService>().logout();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label, style: TextStyle(color: Colors.grey.shade600)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}

extension _EmptyFallback on String {
  String ifEmptyThen(String fallback) => isEmpty ? fallback : this;
}
