import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/pages/patterns/pattern_list.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_patterns_notifier.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class SavedPatternsPage extends ConsumerStatefulWidget {
  const SavedPatternsPage({super.key});

  @override
  ConsumerState<SavedPatternsPage> createState() => _SavedPatternsPageState();
}

class _SavedPatternsPageState extends ConsumerState<SavedPatternsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savedPatternsProvider.notifier).fetchPublicPatterns();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticationState = ref.watch(authenticationProvider);
    final savedPatternsState = ref.watch(savedPatternsProvider);
    final isSignedIn = authenticationState.user != null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Patterns'),
            Tab(text: 'Community Patterns'),
          ],
        ),
        if (savedPatternsState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              savedPatternsState.errorMessage!,
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
                PatternList(
                  patterns: savedPatternsState.userPatterns,
                  isLoading: savedPatternsState.isLoading,
                  isOwned: true,
                  onRefresh: () => ref
                      .read(savedPatternsProvider.notifier)
                      .fetchUserPatterns(),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Sign in to upload and manage your '
                        'patterns',
                      ),
                      const SizedBox(height: 16),
                      PlinkyButton(
                        onPressed: () => showSignInDialog(context),
                        icon: Icons.login,
                        label: 'Sign in',
                      ),
                    ],
                  ),
                ),
              PatternList(
                patterns: savedPatternsState.publicPatterns,
                isLoading: savedPatternsState.isLoading,
                isOwned: false,
                onRefresh: () => ref
                    .read(savedPatternsProvider.notifier)
                    .fetchPublicPatterns(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
