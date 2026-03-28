import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_wavetable.dart';
import 'package:plinkyhub/models/sort_order.dart';
import 'package:plinkyhub/pages/wavetables/wavetable_card.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';
import 'package:plinkyhub/widgets/sort_order_button.dart';

class WavetableList extends ConsumerStatefulWidget {
  const WavetableList({
    required this.wavetables,
    required this.isLoading,
    required this.isOwned,
    required this.onRefresh,
    super.key,
  });

  final List<SavedWavetable> wavetables;
  final bool isLoading;
  final bool isOwned;
  final VoidCallback onRefresh;

  @override
  ConsumerState<WavetableList> createState() => _WavetableListState();
}

class _WavetableListState extends ConsumerState<WavetableList> {
  final _searchController = TextEditingController();
  String _query = '';
  SortOrder _sortOrder = SortOrder.stars;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedWavetable> get _filteredWavetables {
    var wavetables = widget.wavetables.toList();

    if (_query.isNotEmpty) {
      final lower = _query.toLowerCase();
      wavetables = wavetables
          .where(
            (wavetable) =>
                wavetable.name.toLowerCase().contains(lower) ||
                wavetable.username.toLowerCase().contains(lower) ||
                wavetable.description.toLowerCase().contains(lower),
          )
          .toList();
    }

    wavetables.sort((a, b) {
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
    return wavetables;
  }

  int _compareByStarsThenName(SavedWavetable a, SavedWavetable b) {
    final starCmp = b.starCount.compareTo(a.starCount);
    if (starCmp != 0) {
      return starCmp;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.wavetables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.wavetables.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isOwned
                  ? 'No saved wavetables yet'
                  : 'No community wavetables yet',
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

    final filtered = _filteredWavetables;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search wavetables...',
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
                          'wavetable${filtered.length == 1 ? '' : 's'}',
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
                            child: WavetableCard(
                              wavetable: filtered[itemIndex],
                              isOwned: widget.isOwned,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (itemIndex + 1 < filtered.length)
                            Expanded(
                              child: WavetableCard(
                                wavetable: filtered[itemIndex + 1],
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
