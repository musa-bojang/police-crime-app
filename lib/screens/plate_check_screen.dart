import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watchlist_vehicle.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/sync_service.dart';

/// Officer checks a plate against the locally-cached watchlist. Works fully
/// offline; a confirmed hit queues a sighting (with GPS) for sync.
class PlateCheckScreen extends StatefulWidget {
  const PlateCheckScreen({super.key});

  @override
  State<PlateCheckScreen> createState() => _PlateCheckScreenState();
}

class _PlateCheckScreenState extends State<PlateCheckScreen> {
  final _plate = TextEditingController();
  bool _checked = false;
  bool _checking = false;
  List<WatchlistVehicle> _matches = [];

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final raw = _plate.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _checking = true;
      _checked = false;
    });

    final normalized = WatchlistVehicle.normalizePlate(raw);
    final matches =
        await DatabaseService.instance.searchWatchlist(normalized);

    // A hit is intelligence: queue a sighting with GPS, then sync.
    if (matches.isNotEmpty) {
      final position = await LocationService().getCurrentPosition();
      for (final m in matches) {
        await DatabaseService.instance.queueSighting(
          watchlistVehicleId: m.id,
          plateChecked: raw,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );
      }
      if (mounted) context.read<SyncService>().syncNow();
    }

    if (!mounted) return;
    setState(() {
      _matches = matches;
      _checked = true;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plate Check')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              labelText: 'Vehicle plate',
              hintText: 'e.g. BJL 1234',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.directions_car),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _plate.clear();
                  setState(() => _checked = false);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _checking ? null : _check,
              icon: _checking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: Text(_checking ? 'Checking…' : 'Check plate'),
            ),
          ),
          const SizedBox(height: 24),
          if (_checked && _matches.isEmpty) const _NoMatchCard(),
          if (_checked)
            ..._matches.map((m) => _AlertCard(vehicle: m)),
        ],
      ),
    );
  }
}

class _NoMatchCard extends StatelessWidget {
  const _NoMatchCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No alert for this plate.\nNot on the active watchlist.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.vehicle});
  final WatchlistVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) =
        switch (vehicle.severity) {
      'dangerous' => (Colors.red, Icons.warning, 'DANGEROUS'),
      'wanted' => (Colors.orange, Icons.error, 'WANTED'),
      _ => (Colors.amber.shade700, Icons.info, 'CAUTION'),
    };

    final details = [
      if (vehicle.vehicleColor != null) vehicle.vehicleColor,
      if (vehicle.vehicleMake != null) vehicle.vehicleMake,
      if (vehicle.vehicleType != null) vehicle.vehicleType,
    ].join(' • ');

    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(vehicle.plate,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(details,
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade700)),
              ),
            const Divider(height: 24),
            Text('Reason', style: TextStyle(color: Colors.grey.shade600)),
            Text(vehicle.reason, style: const TextStyle(fontSize: 16)),
            if (vehicle.instructions != null &&
                vehicle.instructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INSTRUCTIONS',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(vehicle.instructions!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sighting recorded and will be reported to base.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
