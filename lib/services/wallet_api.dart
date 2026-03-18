import 'dart:convert';

import 'package:Tiffinity/models/wallet_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WalletApi {
  // ✅ Single confirmed base URL — no fallback that causes 404 spam
  static const String _baseUrl =
      'https://svtechshant.com/tiffin/api/transactions';

  Future<WalletDashboard> fetchDashboard({
    required String ownerId,
    required String ownerType,
  }) async {
    final overview = await fetchWalletOverview(
      ownerId: ownerId,
      ownerType: ownerType,
    );

    List<WalletStatementEntry> statements = const [];
    try {
      statements = await fetchStatements(
        ownerId: ownerId,
        ownerType: ownerType,
      );
    } catch (error) {
      debugPrint('Wallet statement fallback: $error');
    }

    List<WithdrawalRequestModel> withdrawals = const [];
    try {
      withdrawals = await fetchWithdrawalHistory(
        ownerId: ownerId,
        ownerType: ownerType,
      );
    } catch (error) {
      debugPrint('Wallet withdrawal fallback: $error');
    }

    return WalletDashboard(
      overview: overview,
      statements: statements,
      withdrawals: withdrawals,
    );
  }

  Future<WalletOverview> fetchWalletOverview({
    required String ownerId,
    required String ownerType,
  }) async {
    final response = await _post(
      'wallet_balance.php',
      body: {'owner_id': ownerId, 'owner_type': ownerType},
    );

    final map = _extractMap(response);

    return WalletOverview.fromJson({
      "balance": map["balance"],
      "locked_balance": map["locked_balance"],
      "available": map["available"],
    });
  }

  Future<List<WalletStatementEntry>> fetchStatements({
    required String ownerId,
    required String ownerType,
    String period = "all",
  }) async {
    final response = await _post(
      'statement.php',
      body: {'owner_id': ownerId, 'owner_type': ownerType, 'period': period},
    );

    final items =
        _extractList(response).map(WalletStatementEntry.fromJson).toList();

    items.sort(
      (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
        a.createdAt ?? DateTime(2000),
      ),
    );

    return items;
  }

  Future<List<WithdrawalRequestModel>> fetchWithdrawalHistory({
    required String ownerId,
    required String ownerType,
  }) async {
    final response = await _post(
      'withdraw_history.php',
      body: {'owner_id': ownerId, 'owner_type': ownerType},
    );

    final items =
        _extractList(response).map(WithdrawalRequestModel.fromJson).toList();

    items.sort(
      (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
        a.createdAt ?? DateTime(2000),
      ),
    );

    return items;
  }

  Future<String> submitWithdrawRequest({
    required String ownerId,
    required String ownerType,
    required double amount,
  }) async {
    final response = await _post(
      'payment_request.php',
      body: {
        'owner_id': ownerId,
        'owner_type': ownerType,
        'amount': amount.toStringAsFixed(2),
      },
    );

    if (response["request_id"] != null) {
      return "Withdrawal request submitted.";
    }

    final message = response['message']?.toString();

    return message == null || message.isEmpty
        ? 'Withdrawal request submitted successfully.'
        : message;
  }

  Future<Map<String, dynamic>> _post(
    String endpoint, {
    required Map<String, String> body,
  }) async {
    final uri = Uri.parse('$_baseUrl/$endpoint');

    final http.Response response;
    response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: body,
          encoding: Encoding.getByName('utf-8'),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('Wallet POST $uri -> ${response.statusCode} | ${response.body}');

    if (response.body.trim().isEmpty) {
      throw Exception('Empty response from server.');
    }

    // ✅ 404 → throw immediately, no silent retry
    if (response.statusCode == 404) {
      throw Exception('Endpoint not found (404): $endpoint');
    }

    final decoded = _decodeResponse(response.body);

    if (response.statusCode >= 400) {
      throw Exception(
        decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'Request failed with status ${response.statusCode}.',
      );
    }

    if (!_isSuccessfulResponse(decoded) &&
        !_containsUsableData(decoded) &&
        decoded['message'] != null) {
      throw Exception(decoded['message'].toString());
    }

    return decoded;
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final trimmed = body.trim();

    if (trimmed.startsWith('<')) {
      throw Exception('Wallet endpoint returned HTML instead of JSON');
    }

    final decoded = json.decode(trimmed);

    if (decoded is List) {
      return {'data': decoded};
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected wallet response received.');
  }

  bool _isSuccessfulResponse(Map<String, dynamic> json) {
    return json['success'] == true ||
        json['status'] == true ||
        json['status']?.toString().toLowerCase() == 'success';
  }

  bool _containsUsableData(Map<String, dynamic> json) {
    return json.containsKey('balance') ||
        json.containsKey('credit') ||
        json.containsKey('data') ||
        json.containsKey('statements') ||
        json.containsKey('history') ||
        json.containsKey('withdrawals');
  }

  Map<String, dynamic> _extractMap(Map<String, dynamic> json) {
    if (json['data'] is Map<String, dynamic>) {
      return json['data'] as Map<String, dynamic>;
    }
    return json;
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    final dynamic source =
        json['data'] ??
        json['statements'] ??
        json['history'] ??
        json['withdrawals'] ??
        json['requests'] ??
        json['items'] ??
        json['list'];

    if (source is List) {
      return source
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }

    if (json.values.any((value) => value is List)) {
      final list = json.values.firstWhere((value) => value is List) as List;
      return list
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    }

    return const [];
  }

  String _normalizeError(Object? error) {
    if (error == null) return 'Wallet request failed.';

    final raw = error.toString().trim();
    if (raw.startsWith('Exception: '))
      return raw.substring('Exception: '.length);
    if (raw.startsWith('FormatException: '))
      return raw.substring('FormatException: '.length);
    return raw;
  }
}
