import 'package:Tiffinity/controllers/wallet_controller.dart';
import 'package:Tiffinity/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WithdrawHistoryScreen extends StatelessWidget {
  WithdrawHistoryScreen({super.key, required this.controller});

  final WalletController controller;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  Color get _primaryColor => const Color(0xFF1B5450);
  Color get _successColor => const Color(0xFF159A62);
  Color get _pendingColor => const Color(0xFFF08A24);

  @override
  Widget build(BuildContext context) {
    final items =
        controller.dashboard?.withdrawals ?? const <WithdrawalRequestModel>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Withdraw History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: items.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final accent = _statusColor(item.status);

                return Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.account_balance_rounded, color: accent),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currency.format(item.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.createdAt == null
                                  ? 'Date unavailable'
                                  : _dateFormat.format(item.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (item.requestId.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                'Request ID: ${item.requestId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _formatStatus(item.status),
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
              },
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _successColor;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return _pendingColor;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 42, color: _primaryColor),
            const SizedBox(height: 14),
            const Text(
              'No withdrawal requests yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted payout requests will appear here with their latest status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
