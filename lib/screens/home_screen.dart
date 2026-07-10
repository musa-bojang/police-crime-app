import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/offence.dart';
import '../services/offence_store.dart';
import '../services/sync_service.dart';
import 'capture_form_screen.dart';
import 'plate_check_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncService>().syncNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<OffenceStore>();
    final sync = context.watch<SyncService>();
    final offences = store.offences;
    final pending = store.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(pending > 0 ? 'Offences ($pending pending)' : 'Offences'),
        actions: [
          if (sync.syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              tooltip: 'Sync now',
              icon: const Icon(Icons.sync),
              onPressed: () => context.read<SyncService>().syncNow(),
            ),
          IconButton(
            tooltip: 'Plate check',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlateCheckScreen()),
            ),
          ),
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
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
            Icon(Icons.cloud_done, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('Outbox is empty.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text('Everything captured has synced. Tap "New offence" to add one.',
                textAlign: TextAlign.center,
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
    final hasLocation = offence.latitude != null;

    return ListTile(
      leading: const Icon(Icons.directions_car),
      title: Text('${_label(offence.offenceType)}  •  $plate'),
      subtitle: Row(
        children: [
          Text(time),
          if (hasLocation) ...[
            const SizedBox(width: 6),
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
          ],
        ],
      ),
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
