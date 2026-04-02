import 'package:flutter/material.dart';

class SavedFavoritesScreen extends StatelessWidget {
  const SavedFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Essentials')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: const <Widget>[
          Text(
            'Access your recently viewed offices and saved spots quickly.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 18),
          _SectionHeader(title: 'Recently Viewed'),
          SizedBox(height: 8),
          SizedBox(
            height: 172,
            child: _RecentlyViewedRow(),
          ),
          SizedBox(height: 20),
          _SectionHeader(title: 'Saved Offices'),
          SizedBox(height: 10),
          _SavedItemCard(
            title: 'Nairobi County HQ',
            subtitle: 'City Hall Way, CBD',
            badge: 'Primary',
          ),
          _SavedItemCard(
            title: 'Westlands Sub-County Office',
            subtitle: 'Opposite Safaricom HQ',
          ),
          _SavedItemCard(
            title: 'Embakasi East Office',
            subtitle: 'Tassia Estate, Outer Ring Road',
          ),
          SizedBox(height: 20),
          _SectionHeader(title: 'Saved Spots'),
          SizedBox(height: 10),
          _SavedItemCard(
            title: 'Java House Sarit',
            subtitle: 'Café • 5 min walk',
          ),
          _SavedItemCard(
            title: 'Jeevanjee Gardens',
            subtitle: 'Chill Spot • 800m',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _RecentlyViewedRow extends StatelessWidget {
  const _RecentlyViewedRow();

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: const <Widget>[
        _RecentCard(title: 'Huduma Center GPO', subtitle: 'Central Ward'),
        _RecentCard(title: 'Strathmore Spot', subtitle: 'Nairobi West'),
        _RecentCard(title: 'KCB Towers Office', subtitle: 'Upper Hill'),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: <Color>[Color(0xFFE53935), Color(0xFF1C1C1C)]),
                ),
                child: const Center(child: Icon(Icons.history_rounded, color: Colors.white)),
              ),
              const SizedBox(height: 10),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  const _SavedItemCard({
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final String? badgeText = badge;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black12,
          ),
          child: const Icon(Icons.image_rounded),
        ),
        title: Row(
          children: <Widget>[
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_remove_rounded),
        ),
      ),
    );
  }
}
