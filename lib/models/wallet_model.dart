class WalletOverview {
  const WalletOverview({
    required this.balance,
    required this.lockedBalance,
    required this.availableBalance,
  });

  final double balance;
  final double lockedBalance;
  final double availableBalance;

  factory WalletOverview.fromJson(Map<String, dynamic> json) {
    return WalletOverview(
      balance: _toDouble(json['balance']),
      lockedBalance: _toDouble(
        json['locked_balance'] ?? json['lockedBalance'],
      ),
      availableBalance: _toDouble(
        json['available'] ??
            json['available_balance'] ??
            json['availableBalance'],
      ),
    );
  }
}

class WalletStatementEntry {
  const WalletStatementEntry({
    required this.title,
    required this.credit,
    required this.debit,
    required this.balanceAfter,
    required this.createdAt,
  });

  final String title;
  final double credit;
  final double debit;
  final double balanceAfter;
  final DateTime? createdAt;

  bool get isCredit => credit > 0;
  double get amount => isCredit ? credit : debit;

  factory WalletStatementEntry.fromJson(Map<String, dynamic> json) {
    return WalletStatementEntry(
      title: (json['title'] ?? 'Wallet entry').toString(),
      credit: _toDouble(json['credit']),
      debit: _toDouble(json['debit']),
      balanceAfter: _toDouble(
        json['balance_after'] ?? json['balanceAfter'] ?? json['balance'],
      ),
      createdAt: _toDateTime(json['created_at'] ?? json['date']),
    );
  }
}

class WithdrawalRequestModel {
  const WithdrawalRequestModel({
    required this.requestId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String requestId;
  final double amount;
  final String status;
  final DateTime? createdAt;

  bool get isPending => status.toLowerCase() == 'pending';

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      requestId: (json['request_id'] ?? json['id'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _toDateTime(
        json['created_at'] ?? json['date'] ?? json['requested_at'],
      ),
    );
  }
}

class WalletDashboard {
  const WalletDashboard({
    required this.overview,
    required this.statements,
    required this.withdrawals,
  });

  final WalletOverview overview;
  final List<WalletStatementEntry> statements;
  final List<WithdrawalRequestModel> withdrawals;

  double get todayEarning {
    final now = DateTime.now();
    return statements
        .where(
          (entry) =>
              entry.isCredit &&
              entry.createdAt != null &&
              entry.createdAt!.year == now.year &&
              entry.createdAt!.month == now.month &&
              entry.createdAt!.day == now.day,
        )
        .fold(0.0, (sum, entry) => sum + entry.credit);
  }

  double get totalEarning => statements
      .where((entry) => entry.isCredit)
      .fold(0.0, (sum, entry) => sum + entry.credit);

  double get pendingWithdrawal => withdrawals
      .where((entry) => entry.isPending)
      .fold(0.0, (sum, entry) => sum + entry.amount);
}

double _toDouble(dynamic value) {
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  try {
    return DateTime.parse(value.toString()).toLocal();
  } catch (_) {
    return null;
  }
}
