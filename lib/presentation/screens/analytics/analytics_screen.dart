import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import 'widgets/largest_files_table.dart';
import 'widgets/access_time_card.dart';
import 'widgets/cost_savings_tab.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(analyticsInitialTabProvider);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    // Reset so the next navigation to analytics opens tab 0 unless overridden.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsInitialTabProvider.notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    if (account == null || !account.hasBeenScanned) {
      return EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No data yet',
        subtitle: account == null
            ? 'Select an account first.'
            : 'Scan "${account.label}" to see analytics.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics — ${account.label}',
            overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Largest Files'),
            Tab(text: 'Access Age'),
            Tab(text: 'Cost Savings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LargestFilesTable(accountId: account.id),
          AccessTimeTab(accountId: account.id),
          CostSavingsTab(accountId: account.id),
        ],
      ),
    );
  }
}
