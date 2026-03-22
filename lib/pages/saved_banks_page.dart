import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plinkyhub/models/saved_bank.dart';
import 'package:plinkyhub/models/saved_patch.dart';
import 'package:plinkyhub/models/saved_sample.dart';
import 'package:plinkyhub/state/authentication_notifier.dart';
import 'package:plinkyhub/state/saved_banks_notifier.dart';
import 'package:plinkyhub/state/saved_patches_notifier.dart';
import 'package:plinkyhub/state/saved_samples_notifier.dart';
import 'package:plinkyhub/widgets/authentication_button.dart';
import 'package:plinkyhub/widgets/plinky_button.dart';

class SavedBanksPage extends ConsumerStatefulWidget {
  const SavedBanksPage({super.key});

  @override
  ConsumerState<SavedBanksPage> createState() => _SavedBanksPageState();
}

class _SavedBanksPageState extends ConsumerState<SavedBanksPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        ref.read(savedBanksProvider.notifier).fetchPublicBanks();
      }
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
    final savedBanksState = ref.watch(savedBanksProvider);
    final isSignedIn = authenticationState.user != null;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Banks'),
            Tab(text: 'Create Bank'),
            Tab(text: 'Community Banks'),
          ],
        ),
        if (savedBanksState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              savedBanksState.errorMessage!,
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
                _BankList(
                  banks: savedBanksState.userBanks,
                  isLoading: savedBanksState.isLoading,
                  isOwned: true,
                  onRefresh: () =>
                      ref.read(savedBanksProvider.notifier).fetchUserBanks(),
                )
              else
                const _SignInPrompt(
                  message: 'Sign in to save and manage your banks',
                ),
              if (isSignedIn)
                const _CreateBankTab()
              else
                const _SignInPrompt(
                  message: 'Sign in to create banks',
                ),
              _BankList(
                banks: savedBanksState.publicBanks,
                isLoading: savedBanksState.isLoading,
                isOwned: false,
                onRefresh: () =>
                    ref.read(savedBanksProvider.notifier).fetchPublicBanks(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 64),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          PlinkyButton(
            onPressed: () => showSignInDialog(context),
            icon: Icons.login,
            label: 'Sign in',
          ),
        ],
      ),
    );
  }
}

class _BankList extends ConsumerWidget {
  const _BankList({
    required this.banks,
    required this.isLoading,
    required this.isOwned,
    required this.onRefresh,
  });

  final List<SavedBank> banks;
  final bool isLoading;
  final bool isOwned;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && banks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (banks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOwned ? 'No saved banks yet' : 'No community banks yet',
            ),
            const SizedBox(height: 8),
            PlinkyButton(
              onPressed: onRefresh,
              icon: Icons.refresh,
              label: 'Refresh',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: banks.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${banks.length} bank${banks.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            );
          }

          final bank = banks[index - 1];
          return _BankCard(bank: bank, isOwned: isOwned);
        },
      ),
    );
  }
}

class _BankCard extends ConsumerWidget {
  const _BankCard({
    required this.bank,
    required this.isOwned,
  });

  final SavedBank bank;
  final bool isOwned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filledSlots = bank.slots.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bank.name.isEmpty ? '(unnamed)' : bank.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    '$filledSlots/32 patches',
                    style: theme.textTheme.bodySmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (bank.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bank.description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(bank.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isOwned) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      bank.isPublic ? Icons.public : Icons.public_off,
                      size: 20,
                    ),
                    tooltip: bank.isPublic ? 'Make private' : 'Make public',
                    onPressed: () {
                      ref.read(savedBanksProvider.notifier).updateBank(
                            bank.id,
                            isPublic: !bank.isPublic,
                          );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete bank',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bank?'),
        content: Text(
          'Are you sure you want to delete '
          '"${bank.name.isEmpty ? '(unnamed)' : bank.name}"?',
        ),
        actions: [
          PlinkyButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.close,
            label: 'Cancel',
          ),
          PlinkyButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(savedBanksProvider.notifier).deleteBank(bank.id);
            },
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _CreateBankTab extends ConsumerStatefulWidget {
  const _CreateBankTab();

  @override
  ConsumerState<_CreateBankTab> createState() => _CreateBankTabState();
}

class _CreateBankTabState extends ConsumerState<_CreateBankTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  final List<({String? patchId, String? sampleId})> _slots =
      List.generate(32, (_) => (patchId: null, sampleId: null));

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedBanksState = ref.watch(savedBanksProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Bank name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Share publicly'),
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
          const SizedBox(height: 16),
          Text(
            'Patch Slots',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 32,
            itemBuilder: (context, index) {
              return _BankSlotTile(
                slotNumber: index,
                patchId: _slots[index].patchId,
                sampleId: _slots[index].sampleId,
                onPatchChanged: (patchId) {
                  setState(() {
                    _slots[index] = (
                      patchId: patchId,
                      sampleId: _slots[index].sampleId,
                    );
                  });
                },
                onSampleChanged: (sampleId) {
                  setState(() {
                    _slots[index] = (
                      patchId: _slots[index].patchId,
                      sampleId: sampleId,
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: PlinkyButton(
              onPressed: savedBanksState.isLoading ? null : _saveBank,
              icon: Icons.save,
              label: 'Save Bank',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _saveBank() {
    final slots = <({int slotNumber, String? patchId, String? sampleId})>[];
    for (var i = 0; i < 32; i++) {
      slots.add((
        slotNumber: i,
        patchId: _slots[i].patchId,
        sampleId: _slots[i].sampleId,
      ));
    }

    ref.read(savedBanksProvider.notifier).saveBank(
          _nameController.text,
          description: _descriptionController.text,
          isPublic: _isPublic,
          slots: slots,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bank saved')),
    );

    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _isPublic = false;
      for (var i = 0; i < 32; i++) {
        _slots[i] = (patchId: null, sampleId: null);
      }
    });
  }
}

class _BankSlotTile extends ConsumerWidget {
  const _BankSlotTile({
    required this.slotNumber,
    required this.patchId,
    required this.sampleId,
    required this.onPatchChanged,
    required this.onSampleChanged,
  });

  final int slotNumber;
  final String? patchId;
  final String? sampleId;
  final ValueChanged<String?> onPatchChanged;
  final ValueChanged<String?> onSampleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final patches = ref.watch(
      savedPatchesProvider.select((state) => state.userPatches),
    );
    final samples = ref.watch(
      savedSamplesProvider.select((state) => state.userSamples),
    );

    final patchName = patchId != null
        ? patches
                .where((patch) => patch.id == patchId)
                .firstOrNull
                ?.name ??
            '(unknown)'
        : 'Empty';
    final sampleName = sampleId != null
        ? samples
                .where((sample) => sample.id == sampleId)
                .firstOrNull
                ?.name ??
            '(unknown)'
        : 'None';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${slotNumber + 1}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _showPatchPicker(context, patches),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patchName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sampleName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'patch',
                  child: Text('Pick patch'),
                ),
                const PopupMenuItem(
                  value: 'sample',
                  child: Text('Pick sample'),
                ),
                if (patchId != null || sampleId != null)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear slot'),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'patch':
                    _showPatchPicker(context, patches);
                  case 'sample':
                    _showSamplePicker(context, samples);
                  case 'clear':
                    onPatchChanged(null);
                    onSampleChanged(null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPatchPicker(BuildContext context, List<SavedPatch> patches) {
    showDialog<String>(
      context: context,
      builder: (context) => _PatchPickerDialog(patches: patches),
    ).then((selectedId) {
      if (selectedId != null) {
        onPatchChanged(selectedId);
      }
    });
  }

  void _showSamplePicker(BuildContext context, List<SavedSample> samples) {
    showDialog<String>(
      context: context,
      builder: (context) => _SamplePickerDialog(samples: samples),
    ).then((selectedId) {
      if (selectedId != null) {
        onSampleChanged(selectedId);
      }
    });
  }
}

class _PatchPickerDialog extends StatelessWidget {
  const _PatchPickerDialog({required this.patches});

  final List<SavedPatch> patches;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a patch'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: patches.isEmpty
            ? const Center(child: Text('No saved patches'))
            : ListView.builder(
                itemCount: patches.length,
                itemBuilder: (context, index) {
                  final patch = patches[index];
                  return ListTile(
                    title: Text(
                      patch.name.isEmpty ? '(unnamed)' : patch.name,
                    ),
                    subtitle: patch.category.isNotEmpty
                        ? Text(patch.category)
                        : null,
                    onTap: () => Navigator.of(context).pop(patch.id),
                  );
                },
              ),
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.close,
          label: 'Cancel',
        ),
      ],
    );
  }
}

class _SamplePickerDialog extends StatelessWidget {
  const _SamplePickerDialog({required this.samples});

  final List<SavedSample> samples;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a sample'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: samples.isEmpty
            ? const Center(child: Text('No saved samples'))
            : ListView.builder(
                itemCount: samples.length,
                itemBuilder: (context, index) {
                  final sample = samples[index];
                  return ListTile(
                    title: Text(
                      sample.name.isEmpty ? '(unnamed)' : sample.name,
                    ),
                    subtitle: sample.description.isNotEmpty
                        ? Text(sample.description)
                        : null,
                    onTap: () => Navigator.of(context).pop(sample.id),
                  );
                },
              ),
      ),
      actions: [
        PlinkyButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icons.close,
          label: 'Cancel',
        ),
      ],
    );
  }
}
