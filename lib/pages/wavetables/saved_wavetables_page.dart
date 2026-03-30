import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plinkyhub/pages/wavetables/draw_wavetable_tab.dart';
import 'package:plinkyhub/pages/wavetables/upload_wavetable_tab.dart';
import 'package:plinkyhub/pages/wavetables/wavetable_card.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_wavetables_notifier.dart';
import 'package:plinkyhub/widgets/searchable_item_list.dart';
import 'package:plinkyhub/widgets/sign_in_prompt.dart';

enum WavetableTab {
  my,
  community,
  create,
  upload,
}

class SavedWavetablesPage extends ConsumerStatefulWidget {
  const SavedWavetablesPage({this.initialTab, super.key});

  final String? initialTab;

  @override
  ConsumerState<SavedWavetablesPage> createState() =>
      _SavedWavetablesPageState();
}

class _SavedWavetablesPageState extends ConsumerState<SavedWavetablesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTab != null
        ? WavetableTab.values
              .firstWhere(
                (t) => t.name == widget.initialTab,
                orElse: () => WavetableTab.my,
              )
              .index
        : 0;

    _tabController = TabController(
      length: WavetableTab.values.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedWavetablesProvider.notifier).fetchPublicWavetables();
      if (initialIndex == 0) {
        ref.read(savedWavetablesProvider.notifier).fetchUserWavetables();
      }
    });
  }

  @override
  void didUpdateWidget(SavedWavetablesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      final tab = WavetableTab.values.firstWhere(
        (t) => t.name == widget.initialTab,
        orElse: () => WavetableTab.my,
      );
      if (_tabController.index != tab.index) {
        _tabController.animateTo(tab.index);
      }
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final tabName = WavetableTab.values[_tabController.index].name;
      context.go('/wavetables/$tabName');
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
    final savedWavetablesState = ref.watch(savedWavetablesProvider);
    final isSignedIn = authenticationState.user != null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Wavetables'),
            Tab(text: 'Community Wavetables'),
            Tab(text: 'Create Wavetable'),
            Tab(text: 'Upload'),
          ],
        ),
        if (savedWavetablesState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              savedWavetablesState.errorMessage!,
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
                  items: savedWavetablesState.userWavetables,
                  starredItems: savedWavetablesState.starredWavetables,
                  isLoading: savedWavetablesState.isLoading,
                  isOwned: true,
                  onRefresh: () => ref
                      .read(savedWavetablesProvider.notifier)
                      .fetchUserWavetables(),
                  itemBuilder: (wavetable) => WavetableCard(
                    wavetable: wavetable,
                    isOwned: wavetable.userId == authenticationState.user?.id,
                  ),
                  itemLabel: 'wavetable',
                )
              else
                const SignInPrompt(
                  message: 'Sign in to upload and manage your wavetables',
                ),
              SearchableItemList(
                items: savedWavetablesState.publicWavetables,
                isLoading: savedWavetablesState.isLoading,
                isOwned: false,
                onRefresh: () => ref
                    .read(savedWavetablesProvider.notifier)
                    .fetchPublicWavetables(),
                itemBuilder: (wavetable) => WavetableCard(
                  wavetable: wavetable,
                  isOwned: false,
                ),
                itemLabel: 'wavetable',
              ),
              if (isSignedIn)
                DrawWavetableTab(
                  onCreated: () => _tabController.animateTo(0),
                )
              else
                const SignInPrompt(
                  message: 'Sign in to create wavetables',
                ),
              if (isSignedIn)
                UploadWavetableTab(
                  onUploaded: () => _tabController.animateTo(0),
                )
              else
                const SignInPrompt(
                  message: 'Sign in to create wavetables',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
