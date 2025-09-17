// Simple in-memory pairing service that works across browser instances
// In production, this would be a backend service

class PairingService {
  static final PairingService _instance = PairingService._internal();
  factory PairingService() => _instance;
  PairingService._internal();

  // Store pairing codes in memory (shared across all instances in same browser session)
  static final Map<String, Map<String, dynamic>> _pairingCodes = {};

  // Generate a pairing code for a user
  String generateCode(String userPhone) {
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    _pairingCodes[code] = {
      'phone': userPhone,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Clean up old codes (older than 10 minutes)
    _cleanupOldCodes();

    return code;
  }

  // Check if a code is valid and get the partner's phone
  Map<String, dynamic>? validateCode(String code) {
    final data = _pairingCodes[code];
    if (data != null) {
      // Remove the code after successful validation
      _pairingCodes.remove(code);
      return data;
    }
    return null;
  }

  // Generate an invite link
  String generateInviteLink(String code) {
    // Get the current URL base
    final baseUrl = Uri.base.toString().split('?')[0].split('#')[0];
    return '${baseUrl}#/invite/$code';
  }

  // Parse invite code from URL
  static String? getInviteCodeFromUrl() {
    final uri = Uri.base;
    if (uri.fragment.startsWith('invite/')) {
      return uri.fragment.substring(7);
    }
    return null;
  }

  void _cleanupOldCodes() {
    final now = DateTime.now();
    _pairingCodes.removeWhere((code, data) {
      final timestamp = DateTime.parse(data['timestamp']);
      return now.difference(timestamp).inMinutes > 10;
    });
  }

  // For debugging
  void printAllCodes() {
    print('Active pairing codes: $_pairingCodes');
  }
}