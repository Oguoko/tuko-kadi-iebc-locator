import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/features/home/application/offices_provider.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _recentSearches = <String>['Lang’ata', 'Westlands', 'Mombasa'];
  final List<String> _suggestions = <String>['Kibra', 'Nakuru Town', 'Kisumu Central', 'Eldoret East'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Office> offices = ref.watch(officesProvider).maybeWhen(
          data: (List<Office> data) => data,
          orElse: () => <Office>[],
        );
    final String query = _controller.text.trim().toLowerCase();
    final List<Office> results = query.isEmpty
        ? offices.take(8).toList(growable: false)
        : offices
            .where(
              (Office office) => office.constituency.toLowerCase().contains(query) || office.county.toLowerCase().contains(query) || office.officeLocation.toLowerCase().contains(query),
            )
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Search IEBC Offices')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: <Widget>[
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by constituency, county, or office',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Suggested', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (String text) => ActionChip(
                    label: Text(text),
                    onPressed: () {
                      _controller.text = text;
                      _controller.selection = TextSelection.collapsed(offset: text.length);
                      setState(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Recent Searches', style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => setState(_recentSearches.clear),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: _recentSearches
                  .map(
                    (String search) => ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(search),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _recentSearches.remove(search)),
                      ),
                      onTap: () {
                        _controller.text = search;
                        _controller.selection = TextSelection.collapsed(offset: search.length);
                        setState(() {});
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 22),
          Text('Search Results', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (results.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No offices found. Try a different search keyword.'),
              ),
            )
          else
            ...results.map(
              (Office office) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: const CircleAvatar(child: Icon(Icons.location_on_rounded)),
                  title: Text(office.constituency, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${office.county} • ${office.officeLocation}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    if (!_recentSearches.contains(office.constituency)) {
                      _recentSearches.insert(0, office.constituency);
                    }
                    context.push(AppRoutes.officeDetails, extra: office);
                    setState(() {});
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
