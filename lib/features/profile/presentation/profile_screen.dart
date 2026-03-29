import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: const <Widget>[
          _ProfileHero(),
          SizedBox(height: 20),
          _SectionCard(
            title: 'System Health / App State',
            items: <_ProfileItemData>[
              _ProfileItemData(icon: Icons.cloud_done_rounded, title: 'API connectivity', subtitle: 'Google Maps and Places services active'),
              _ProfileItemData(icon: Icons.location_searching_rounded, title: 'Location access', subtitle: 'Enabled (high-accuracy mode)'),
              _ProfileItemData(icon: Icons.storage_rounded, title: 'Cache status', subtitle: 'Last sync: moments ago'),
            ],
          ),
          SizedBox(height: 14),
          _SectionCard(
            title: 'Access & Settings',
            items: <_ProfileItemData>[
              _ProfileItemData(icon: Icons.manage_accounts_rounded, title: 'Account preferences', subtitle: 'Name, language, and defaults'),
              _ProfileItemData(icon: Icons.security_rounded, title: 'Security & privacy', subtitle: 'Permissions and data controls'),
              _ProfileItemData(icon: Icons.notifications_active_rounded, title: 'Alerts', subtitle: 'Polling updates and reminders'),
            ],
          ),
          SizedBox(height: 14),
          _SectionCard(
            title: 'Search History',
            items: <_ProfileItemData>[
              _ProfileItemData(icon: Icons.history_rounded, title: 'Recent: Westlands', subtitle: 'Viewed office details and nearby spots'),
              _ProfileItemData(icon: Icons.history_rounded, title: 'Recent: Kisumu Central', subtitle: 'Viewed route and requirements'),
            ],
          ),
          SizedBox(height: 14),
          _SectionCard(
            title: 'Quick Tools',
            items: <_ProfileItemData>[
              _ProfileItemData(icon: Icons.qr_code_scanner_rounded, title: 'Scan office QR', subtitle: 'Jump to verified office details'),
              _ProfileItemData(icon: Icons.share_rounded, title: 'Share app', subtitle: 'Invite friends and family'),
              _ProfileItemData(icon: Icons.help_center_rounded, title: 'Help center', subtitle: 'FAQs and support resources'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE53935),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('TUKO KADI User', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Civic services companion', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            OutlinedButton(onPressed: () {}, child: const Text('Edit')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<_ProfileItemData> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            ...items.map(
              (_ProfileItemData item) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: Colors.red),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItemData {
  const _ProfileItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
