import 'package:Tiffinity/controllers/wallet_controller.dart';
import 'package:Tiffinity/models/wallet_model.dart';
import 'package:Tiffinity/views/pages/admin_pages/wallet_history_screen.dart';
import 'package:Tiffinity/views/pages/admin_pages/withdraw_history_screen.dart';
import 'package:Tiffinity/views/pages/admin_pages/withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  final String ownerId;
  final String ownerType;

  const WalletScreen({
    super.key,
    required this.ownerId,
    required this.ownerType,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletController _controller;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM, hh:mm a');

  Color get _primaryColor => const Color(0xFF1B5450);
  Color get _surfaceTint => const Color(0xFFEAF6F3);
  Color get _highlightColor => const Color(0xFF0F8A7B);
  Color get _successColor => const Color(0xFF159A62);
  Color get _warningColor => const Color(0xFFF08A24);

  @override
  void initState() {
    super.initState();
    _controller = WalletController(
      ownerId: widget.ownerId,
      ownerType: widget.ownerType,
    )..loadWallet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openWithdrawFlow() async {
    if (_controller.dashboard == null) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawScreen(controller: _controller),
      ),
    );

    if (result == true && mounted) {
      _showSnackBar(
        'Withdrawal request submitted successfully.',
        isError: false,
      );
    }
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalletHistoryScreen(controller: _controller),
      ),
    );
  }

  Future<void> _openWithdrawHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawHistoryScreen(controller: _controller),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dashboard = _controller.dashboard;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F8),
          body: RefreshIndicator(
            onRefresh: _controller.refresh,
            color: _primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const _WalletAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child:
                        _controller.isLoading && dashboard == null
                            ? _buildLoadingState()
                            : dashboard == null
                            ? _buildErrorState()
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBalanceHero(dashboard),
                                const SizedBox(height: 18),
                                _buildQuickActions(),
                                const SizedBox(height: 18),
                                _buildStatsGrid(dashboard),
                                const SizedBox(height: 18),
                                _buildHighlightsCard(dashboard),
                                const SizedBox(height: 18),
                                _buildRecentActivity(dashboard),
                                const SizedBox(height: 18),
                                _buildWithdrawalPreview(dashboard),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        5,
        (index) => Container(
          margin: EdgeInsets.only(bottom: index == 4 ? 0 : 16),
          height: index == 0 ? 220 : 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 44,
            color: _primaryColor,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load wallet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.45),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _controller.refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHero(WalletDashboard dashboard) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF113D38), _primaryColor, _highlightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mess Wallet',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Track settlements and payouts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(dashboard.overview.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Available',
                  value: _currency.format(dashboard.overview.availableBalance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Locked',
                  value: _currency.format(dashboard.overview.lockedBalance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            title: 'Withdraw',
            subtitle: 'Request payout',
            icon: Icons.north_east_rounded,
            iconColor: Colors.white,
            background: LinearGradient(
              colors: [_primaryColor, _highlightColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: _openWithdrawFlow,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            title: 'History',
            subtitle: 'View entries',
            icon: Icons.receipt_long_rounded,
            iconColor: _primaryColor,
            backgroundColor: Colors.white,
            borderColor: _surfaceTint,
            onTap: _openHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(WalletDashboard dashboard) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Today\'s earning',
            value: _currency.format(dashboard.todayEarning),
            icon: Icons.wb_sunny_outlined,
            color: _warningColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Total earning',
            value: _currency.format(dashboard.totalEarning),
            icon: Icons.trending_up_rounded,
            color: _successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsCard(WalletDashboard dashboard) {
    return _SectionCard(
      title: 'Wallet summary',
      actionLabel: _controller.isLoading ? 'Refreshing...' : 'Refresh',
      onAction: _controller.isLoading ? null : _controller.refresh,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Available balance',
            value: _currency.format(dashboard.overview.availableBalance),
            valueColor: _primaryColor,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Locked balance',
            value: _currency.format(dashboard.overview.lockedBalance),
            valueColor: _warningColor,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Pending withdrawal',
            value: _currency.format(dashboard.pendingWithdrawal),
            valueColor: _successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(WalletDashboard dashboard) {
    final items = dashboard.statements.take(3).toList();

    return _SectionCard(
      title: 'Recent earnings history',
      actionLabel: dashboard.statements.isEmpty ? null : 'View all',
      onAction: dashboard.statements.isEmpty ? null : _openHistory,
      child:
          items.isEmpty
              ? const _EmptyState(
                title: 'No earnings yet',
                subtitle:
                    'Settlements from the statement API will appear here.',
              )
              : Column(
                children:
                    items
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransactionTile(
                              title: entry.title,
                              subtitle:
                                  entry.createdAt == null
                                      ? 'Date unavailable'
                                      : _dateFormat.format(entry.createdAt!),
                              amount: _currency.format(entry.amount),
                              typeLabel: entry.isCredit ? 'Credit' : 'Debit',
                              isCredit: entry.isCredit,
                              balanceLabel:
                                  'Balance ${_currency.format(entry.balanceAfter)}',
                              successColor: _successColor,
                              debitColor: _warningColor,
                            ),
                          ),
                        )
                        .toList(),
              ),
    );
  }

  Widget _buildWithdrawalPreview(WalletDashboard dashboard) {
    final items = dashboard.withdrawals.take(3).toList();

    return _SectionCard(
      title: 'Withdraw history',
      actionLabel: 'View all',
      onAction: _openWithdrawHistory,
      child:
          items.isEmpty
              ? const _EmptyState(
                title: 'No withdrawal requests yet',
                subtitle:
                    'Once a payout request is created, it will show up here.',
              )
              : Column(
                children:
                    items
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WithdrawalTile(
                              amount: _currency.format(entry.amount),
                              status: entry.status,
                              date:
                                  entry.createdAt == null
                                      ? 'Date unavailable'
                                      : _dateFormat.format(entry.createdAt!),
                              primaryColor: _primaryColor,
                              successColor: _successColor,
                              warningColor: _warningColor,
                            ),
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

class _WalletAppBar extends StatelessWidget {
  const _WalletAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF4F7F8),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Wallet',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5450),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.background,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? background;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: background,
            borderRadius: BorderRadius.circular(22),
            border:
                borderColor == null ? null : Border.all(color: borderColor!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      background == null
                          ? const Color(0xFFEAF6F3)
                          : Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            background == null ? Colors.black87 : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            background == null
                                ? Colors.grey.shade600
                                : Colors.white.withOpacity(0.76),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.typeLabel,
    required this.isCredit,
    required this.balanceLabel,
    required this.successColor,
    required this.debitColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String typeLabel;
  final bool isCredit;
  final String balanceLabel;
  final Color successColor;
  final Color debitColor;

  @override
  Widget build(BuildContext context) {
    final accent = isCredit ? successColor : debitColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({
    required this.amount,
    required this.status,
    required this.date,
    required this.primaryColor,
    required this.successColor,
    required this.warningColor,
  });

  final String amount;
  final String status;
  final String date;
  final Color primaryColor;
  final Color successColor;
  final Color warningColor;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final accent =
        normalizedStatus == 'approved'
            ? successColor
            : normalizedStatus == 'rejected'
            ? Colors.red.shade600
            : warningColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.account_balance_rounded, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.isEmpty
                  ? 'Pending'
                  : '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: Colors.grey.shade400, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
