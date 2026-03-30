import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plinkyhub/pages/presets/preset_card.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_presets_notifier.dart';
import 'package:plinkyhub/widgets/searchable_item_list.dart';
import 'package:plinkyhub/widgets/sign_in_prompt.dart';

enum PresetTab {
  my,
  community,
}

class SavedPresetsPage extends ConsumerStatefulWidget {
  const SavedPresetsPage({this.initialTab, super.key});

  final String? initialTab;

  @override
  ConsumerState<SavedPresetsPage> createState() => _SavedPresetsPageState();
}

class _SavedPresetsPageState extends ConsumerState<SavedPresetsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab != null
        ? PresetTab.values
              .firstWhere(
                (t) => t.name == widget.initialTab,
                orElse: () => PresetTab.my,
              )
              .index
        : 0;

    _tabController = TabController(
      length: PresetTab.values.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedPresetsProvider.notifier).fetchPublicPresets();
      if (initialIndex == 0) {
        ref.read(savedPresetsProvider.notifier).fetchUserPresets();
      }
    });
  }

  @override
  void didUpdateWidget(SavedPresetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      final tab = PresetTab.values.firstWhere(
        (t) => t.name == widget.initialTab,
        orElse: () => PresetTab.my,
      );
      if (_tabController.index != tab.index) {
        _tabController.animateTo(tab.index);
      }
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tabName = PresetTab.values[_tabController.index].name;
      context.go('/presets/$tabName');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationProvider);
    final savedPresetsState = ref.watch(savedPresetsProvider);
    final isSignedIn = authenticationState.user != null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Presets'),
            Tab(text: 'Community Presets'),
          ],
        ),
        if (savedPresetsState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              savedPresetsState.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              if (isSignedIn)
                SearchableItemList(
                  items: savedPresetsState.userPresets,
                  starredItems: savedPresetsState.starredPresets,
                  isLoading: savedPresetsState.isLoading,
                  isOwned: true,
                  onRefresh: () => ref
                      .read(savedPresetsProvider.notifier)
                      .fetchUserPresets(),
                  itemBuilder: (preset) => PresetCard(
                    preset: preset,
                    isOwned: preset.userId == authenticationState.user?.id,
                  ),
                  itemLabel: 'preset',
                )
              else
                const SignInPrompt(
                  message: 'Sign in to save and manage your presets',
                ),
              SearchableItemList(
                items: savedPresetsState.publicPresets,
                isLoading: savedPresetsState.isLoading,
                isOwned: false,
                onRefresh: () => ref
                    .read(savedPresetsProvider.notifier)
                    .fetchPublicPresets(),
                itemBuilder: (preset) => PresetCard(
                  preset: preset,
                  isOwned: false,
                ),
                itemLabel: 'preset',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
