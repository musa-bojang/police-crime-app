import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/offence.dart';
import '../services/auth_service.dart';
import '../services/offence_store.dart';
import 'capture_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OffenceStore>();
    final offences = store.offences;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offences'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: offences.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              itemCount: offences.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _OffenceTile(offence: offences[i]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CaptureFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New offence'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No offences captured yet.',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('Tap "New offence" to record one.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _OffenceTile extends StatelessWidget {
  const _OffenceTile({required this.offence});
  final Offence offence;

  String _label(String raw) =>
      raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('d MMM, HH:mm').format(offence.capturedAt);
    final plate = offence.vehiclePlate ?? 'No plate';

    return ListTile(
      leading: const Icon(Icons.directions_car),
      title: Text('${_label(offence.offenceType)}  •  $plate'),
      subtitle: Text(offence.referenceNumber != null
          ? '${offence.referenceNumber} · $time'
          : time),
      trailing: _SyncChip(status: offence.syncStatus),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = switch (status) {
      'synced' => (Colors.green, 'Synced'),
      'failed' => (Colors.red, 'Failed'),
      _ => (Colors.orange, 'Pending'),
    };

    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
