import 'package:Tiffinity/models/wallet_model.dart';
import 'package:Tiffinity/services/auth_services.dart';
import 'package:Tiffinity/services/wallet_api.dart';
import 'package:flutter/foundation.dart';

class WalletController extends ChangeNotifier {
  WalletController({WalletApi? api}) : _api = api ?? WalletApi();

  final WalletApi _api;

  WalletDashboard? _dashboard;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _ownerId;

  WalletDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get ownerType => 'mess';

  Future<void> loadWallet({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    if (!forceRefresh && _dashboard != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ownerId ??= await _resolveOwnerId();
      _dashboard = await _api.fetchDashboard(
        ownerId: _ownerId!,
        ownerType: ownerType,
      );
    } catch (error) {
      _errorMessage = _normalizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadWallet(forceRefresh: true);
  }

  Future<String> submitWithdrawRequest(double amount) async {
    if (_isSubmitting) {
      return 'Please wait while your request is being submitted.';
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ownerId ??= await _resolveOwnerId();
      final message = await _api.submitWithdrawRequest(
        ownerId: _ownerId!,
        ownerType: ownerType,
        amount: amount,
      );
      await refresh();
      return message;
    } catch (error) {
      final message = _normalizeError(error);
      _errorMessage = message;
      return message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String> _resolveOwnerId() async {
    final currentUser = await AuthService.currentUser;
    final ownerId = currentUser?['uid']?.toString();
    if (ownerId == null || ownerId.isEmpty) {
      throw Exception('Unable to identify the mess owner account.');
    }
    return ownerId;
  }

  String _normalizeError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw.isEmpty ? 'Something went wrong while loading the wallet.' : raw;
  }
}
