import 'dart:html' as html;
import 'dart:convert';
import '../models/game_state.dart';

// Service to sync game state between paired users using localStorage
class GameSyncService {
  // Store Big Branch data
  static void storeBigBranch(String treeId, String userId, List<WantItem> items) {
    final key = 'tree_${treeId}_bigbranch_$userId';
    final data = {
      'userId': userId,
      'items': items.map((item) => {
        'id': item.id,
        'description': item.description,
        'points': item.points,
      }).toList(),
      'completedAt': DateTime.now().toIso8601String(),
    };

    html.window.localStorage[key] = jsonEncode(data);

    // Also mark that this user has completed their Big Branch
    html.window.localStorage['tree_${treeId}_user_${userId}_status'] = 'bigbranch_complete';
  }

  // Get partner's Big Branch
  static List<WantItem>? getPartnerBigBranch(String treeId, String partnerId) {
    final key = 'tree_${treeId}_bigbranch_$partnerId';
    final dataStr = html.window.localStorage[key];

    if (dataStr != null) {
      final data = jsonDecode(dataStr);
      final items = (data['items'] as List).map((item) =>
        WantItem(
          id: item['id'],
          description: item['description'],
          points: item['points'],
        )
      ).toList();
      return items;
    }
    return null;
  }

  // Check if both users have completed Big Branch
  static bool areBothBigBranchesComplete(String treeId, String userId, String partnerId) {
    final userKey = 'tree_${treeId}_user_${userId}_status';
    final partnerKey = 'tree_${treeId}_user_${partnerId}_status';

    final userStatus = html.window.localStorage[userKey];
    final partnerStatus = html.window.localStorage[partnerKey];

    print('Checking completion status:');
    print('  User key: $userKey');
    print('  User status: $userStatus');
    print('  Partner key: $partnerKey');
    print('  Partner status: $partnerStatus');

    return userStatus == 'bigbranch_complete' && partnerStatus == 'bigbranch_complete';
  }

  // Store Little Branch selections
  static void storeLittleBranch(String treeId, String userId, List<WantItem> items) {
    final key = 'tree_${treeId}_littlebranch_$userId';
    final data = {
      'userId': userId,
      'items': items.map((item) => {
        'id': item.id,
        'description': item.description,
        // Don't store points for Little Branch - they should be hidden
      }).toList(),
      'completedAt': DateTime.now().toIso8601String(),
    };

    html.window.localStorage[key] = jsonEncode(data);
    html.window.localStorage['tree_${treeId}_user_${userId}_status'] = 'littlebranch_complete';
  }

  // Get partner's Little Branch (for guessing phase)
  static List<WantItem>? getPartnerLittleBranch(String treeId, String partnerId) {
    final key = 'tree_${treeId}_littlebranch_$partnerId';
    final dataStr = html.window.localStorage[key];

    if (dataStr != null) {
      final data = jsonDecode(dataStr);
      final items = (data['items'] as List).map((item) =>
        WantItem(
          id: item['id'],
          description: item['description'],
          points: 0, // Points hidden until revealed
        )
      ).toList();
      return items;
    }
    return null;
  }

  // Store timer start time
  static void startTimer(String treeId) {
    final key = 'tree_${treeId}_timer_start';
    if (html.window.localStorage[key] == null) {
      html.window.localStorage[key] = DateTime.now().toIso8601String();
    }
  }

  // Get remaining time
  static Duration? getRemainingTime(String treeId) {
    final key = 'tree_${treeId}_timer_start';
    final startStr = html.window.localStorage[key];

    if (startStr != null) {
      final start = DateTime.parse(startStr);
      final elapsed = DateTime.now().difference(start);
      final remaining = const Duration(hours: 144) - elapsed;

      if (remaining.isNegative) {
        return Duration.zero;
      }
      return remaining;
    }
    return null;
  }

  // Get popular suggestions
  static List<String> getPopularSuggestions() {
    return [
      'Quality time together',
      'Help with household chores',
      'A surprise date night',
      'A heartfelt compliment',
      'Physical affection',
      'Help with a project',
      'A home-cooked meal',
      'Active listening',
      'Space when needed',
      'Support during stress',
      'A thoughtful gift',
      'Words of encouragement',
      'Planning a future trip',
      'Exercise together',
      'Learn something new together',
      'Financial support',
      'Career advice',
      'Emotional validation',
      'Help with technology',
      'Organize a space',
      'Run errands together',
      'Share a hobby',
      'Morning coffee in bed',
      'Back massage',
    ];
  }

  // Store user's score
  static void storeScore(String treeId, String userId, int score) {
    final key = 'tree_${treeId}_score_$userId';
    html.window.localStorage[key] = score.toString();
    print('Stored score for user $userId: $score');
  }

  // Get user's score
  static int getScore(String treeId, String userId) {
    final key = 'tree_${treeId}_score_$userId';
    final scoreStr = html.window.localStorage[key];
    if (scoreStr != null) {
      return int.tryParse(scoreStr) ?? 0;
    }
    return 0;
  }

  // Clear all data for a tree
  static void clearTreeData(String treeId) {
    final keys = html.window.localStorage.keys.where((k) => k.contains('tree_$treeId')).toList();
    for (final key in keys) {
      html.window.localStorage.remove(key);
    }
  }
}