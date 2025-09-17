import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';

class WebPairingService {
  // Store a pairing code using the JS bridge
  static bool storeCode(String code, String phoneNumber, [String? displayName]) {
    try {
      final bridge = js.context['pairingBridge'];
      if (bridge != null) {
        bridge.callMethod('storeCode', [code, phoneNumber, displayName ?? phoneNumber]);
        return true;
      }
    } catch (e) {
      print('Error storing pairing code: $e');
    }
    return false;
  }

  // Get a pairing code using the JS bridge
  static Map<String, dynamic>? getCode(String code) {
    try {
      final bridge = js.context['pairingBridge'];
      if (bridge != null) {
        final result = bridge.callMethod('getCode', [code]);
        if (result != null) {
          // Convert JS object to Dart map
          final jsObject = result as js.JsObject;
          return {
            'phone': jsObject['phone'] as String,
            'timestamp': jsObject['timestamp'] as String,
          };
        }
      }
    } catch (e) {
      print('Error getting pairing code: $e');
    }
    return null;
  }

  // Generate a 6-digit code
  static String generateCode() {
    return (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
  }

  // Generate an invite link
  static String generateInviteLink(String code) {
    final baseUrl = html.window.location.href.split('#')[0].split('?')[0];
    return '${baseUrl}#invite/$code';
  }

  // Get invite code from URL
  static String? getInviteCodeFromUrl() {
    final hash = html.window.location.hash;
    if (hash.startsWith('#invite/')) {
      return hash.substring(8);
    }
    return null;
  }

  // List all codes (for debugging)
  static void listAllCodes() {
    try {
      final bridge = js.context['pairingBridge'];
      if (bridge != null) {
        final codes = bridge.callMethod('listCodes', []);
        print('Active pairing codes: $codes');
      }
    } catch (e) {
      print('Error listing codes: $e');
    }
  }
}