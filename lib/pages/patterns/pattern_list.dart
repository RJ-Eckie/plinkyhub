import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_pattern.dart';
import 'package:plinkyhub/models/sort_order.dart';
import 'package:plinkyhub/pages/patterns/pattern_card.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/sort_order_button.dart';

class PatternList extends ConsumerStatefulWidget {
  const PatternList({
    required this.patterns,
    required this.isLoading,
    required this.isOwned,
    required this.onRefresh,
    super.key,
  });

  final List<SavedPattern> patterns;
  final bool isLoading;
  final bool isOwned;
  final VoidCallback onRefresh;

  @override
  ConsumerState<PatternList> createState() => _PatternListState();
}

class _PatternListState extends ConsumerState<PatternList> {
  final _searchController = TextEditingController();
  String _query = '';
  SortOrder _sortOrder = SortOrder.stars;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedPattern> get _filteredPatterns {
    var patterns = widget.patterns.toList();

    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      patterns = patterns
          .where(
            (pattern) =>
                pattern.name.toLowerCase().contains(lower) ||
                pattern.username.toLowerCase().contains(lower) ||
                pattern.description.toLowerCase().contains(lower),
          )
          .toList();
    }

    patterns.sort((a, b) {
      if (_query.isNotEmpty) {
        final lower = _query.toLowerCase();
        final aExact = a.name.toLowerCase() == lower ? 0 : 1;
        final bExact = b.name.toLowerCase() == lower ? 0 : 1;
        final exactCmp = aExact.compareTo(bExact);
        if (exactCmp != 0) {
          return exactCmp;
        }
      }
      return switch (_sortOrder) {
        SortOrder.stars => _compareByStarsThenName(a, b),
        SortOrder.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        SortOrder.newest => b.updatedAt.compareTo(a.updatedAt),
      };
    });
    return patterns;
  }

  int _compareByStarsThenName(SavedPattern a, SavedPattern b) {
    final starCmp = b.starCount.compareTo(a.starCount);
    if (starCmp != 0) {
      return starCmp;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.patterns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.patterns.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isOwned
                  ? 'No saved patterns yet'
                  : 'No community patterns yet',
            ),
            const SizedBox(height: 8),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlinkyButton(
                    onPressed: widget.onRefresh,
                    icon: Icons.refresh,
                    label: 'Refresh',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredPatterns;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search patterns...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} '
                          'pattern${filtered.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        SortOrderButton(
                          value: _sortOrder,
                          onChanged: (order) =>
                              setState(() => _sortOrder = order),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: widget.onRefresh,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: (filtered.length + 1) ~/ 2,
                    itemBuilder: (context, index) {
                      final itemIndex = index * 2;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PatternCard(
                              pattern: filtered[itemIndex],
                              isOwned: widget.isOwned,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (itemIndex + 1 < filtered.length)
                            Expanded(
                              child: PatternCard(
                                pattern: filtered[itemIndex + 1],
                                isOwned: widget.isOwned,
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
