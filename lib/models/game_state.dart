import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';
import '../services/web_pairing_service.dart';

class GameState extends ChangeNotifier {
  bool isAuthenticated = false;
  bool isPremium = false;
  List<WillingTree> trees = [];

  // User management
  UserModel? currentUser;
  UserModel? partner;
  Map<String, UserModel> allUsers = {}; // Store all users by phone number
  String? pairingCode; // For pairing with partner

  // Current active tree
  WillingTree? activeTree;

  // 144-hour timer
  Timer? gameTimer;
  Duration timeRemaining = const Duration(hours: 144);
  bool timerStarted = false;

  void startTimer() {
    if (timerStarted) return;

    timerStarted = true;
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.inSeconds > 0) {
        timeRemaining = Duration(seconds: timeRemaining.inSeconds - 1);
        notifyListeners();
      } else {
        timer.cancel();
        triggerGuessing();
      }
    });
  }

  void triggerGuessing() {
    // Time's up! Send guessing screens
    if (activeTree != null) {
      activeTree!.phase = GamePhase.guessing;
      notifyListeners();
    }
  }

  Future<void> loginWithPhone(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user exists
    final usersJson = prefs.getString('users') ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));

    UserModel user;
    if (users.containsKey(phoneNumber)) {
      // Existing user
      user = UserModel.fromJson(users[phoneNumber]);

      // Check if this user has a partner stored
      final partnerPhone = prefs.getString('partner_$phoneNumber');
      if (partnerPhone != null && users.containsKey(partnerPhone)) {
        partner = UserModel.fromJson(users[partnerPhone]);
      }
    } else {
      // New user
      user = UserModel.create(phoneNumber);
      users[phoneNumber] = user.toJson();
      await prefs.setString('users', jsonEncode(users));
    }

    currentUser = user;
    isAuthenticated = true;

    // Store current session
    await prefs.setString('currentPhone', phoneNumber);

    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    if (currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Update user's display name
    currentUser!.displayName = name;

    // Save to storage
    final usersJson = prefs.getString('users') ?? '{}';
    final users = Map<String, dynamic>.from(jsonDecode(usersJson));
    users[currentUser!.phoneNumber] = currentUser!.toJson();
    await prefs.setString('users', jsonEncode(users));

    notifyListeners();
  }

  Future<void> checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('currentPhone');

    if (phone != null) {
      await loginWithPhone(phone);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentPhone');

    currentUser = null;
    partner = null;
    isAuthenticated = false;
    activeTree = null;

    notifyListeners();
  }

  String generatePairingCode() {
    if (currentUser == null) return '';

    // Generate a new code
    final code = WebPairingService.generateCode();

    // Store it using the web bridge with user's name if available
    final identifier = currentUser!.displayName ?? currentUser!.phoneNumber;
    WebPairingService.storeCode(code, currentUser!.phoneNumber, identifier);

    pairingCode = code;
    notifyListeners();
    return code;
  }

  String getInviteLink() {
    if (pairingCode == null) return '';
    return WebPairingService.generateInviteLink(pairingCode!);
  }

  Future<bool> pairWithCode(String code) async {
    if (currentUser == null) return false;

    // Don't pair with yourself
    if (code == pairingCode) {
      print('Cannot pair with your own code');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    // Get the pairing data from the web bridge
    final pairingData = WebPairingService.getCode(code);

    // Debug: list all codes
    WebPairingService.listAllCodes();

    if (pairingData != null) {
      final partnerPhone = pairingData['phone'] as String;

      // Don't pair with yourself
      if (partnerPhone == currentUser!.phoneNumber) {
        print('Cannot pair with yourself');
        return false;
      }

      // Load or create partner user
      final usersJson = prefs.getString('users') ?? '{}';
      final users = Map<String, dynamic>.from(jsonDecode(usersJson));

      UserModel partnerUser;
      if (users.containsKey(partnerPhone)) {
        partnerUser = UserModel.fromJson(users[partnerPhone]);
      } else {
        // Create user if they don't exist
        partnerUser = UserModel.create(partnerPhone);
        users[partnerPhone] = partnerUser.toJson();
        await prefs.setString('users', jsonEncode(users));
      }

      partner = partnerUser;

      // Create new tree for both users
      activeTree = WillingTree(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        partnerId: partner!.id,
        partnerName: partner!.displayName ?? partner!.phoneNumber,
      );

      // Store bidirectional pairing - both users are paired with each other
      await prefs.setString('partner_${currentUser!.phoneNumber}', partnerPhone);
      await prefs.setString('partner_$partnerPhone', currentUser!.phoneNumber);

      // Also update the partner's user object to include current user as their partner
      partnerUser.partnerId = currentUser!.id;
      users[partnerPhone] = partnerUser.toJson();
      await prefs.setString('users', jsonEncode(users));

      notifyListeners();
      return true;
    } else {
      print('No pairing data found for code: $code');
    }

    return false;
  }

  Future<void> checkForInviteCode() async {
    final inviteCode = WebPairingService.getInviteCodeFromUrl();
    if (inviteCode != null && currentUser != null) {
      final success = await pairWithCode(inviteCode);
      if (success) {
        print('Successfully paired via invite link!');
      }
    }
  }

  void upgradeToPremium() {
    isPremium = true;
    notifyListeners();
  }
}

enum GamePhase {
  buildingBigBranch,
  waitingForPartner,
  selectingLittleBranches,
  playing,
  guessing,
  scoring,
  updating
}

class WillingTree {
  final String id;
  final String partnerId;
  final String partnerName;

  GamePhase phase = GamePhase.buildingBigBranch;

  // Big Branch (wants/needs) with points
  List<WantItem> myBigBranch = [];
  List<WantItem> partnerBigBranch = [];

  // Little Branches (willing list)
  List<WantItem> myLittleBranches = [];
  List<WantItem> partnerLittleBranches = [];

  // Points tracking
  int myPoints = 0;
  int partnerPoints = 0;
  int totalFruit = 0;

  // 25 points to distribute
  int remainingPoints = 25;

  final DateTime createdAt;

  WillingTree({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class WantItem {
  final String id;
  final String description;
  int points; // 1-25 points
  bool isSelected = false;

  WantItem({
    required this.id,
    required this.description,
    this.points = 1,
  });
}