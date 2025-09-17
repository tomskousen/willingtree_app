import 'package:uuid/uuid.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  String? displayName;
  final DateTime createdAt;
  String? currentTreeId;
  String? partnerId;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    required this.createdAt,
    this.currentTreeId,
    this.partnerId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
    'currentTreeId': currentTreeId,
    'partnerId': partnerId,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    phoneNumber: json['phoneNumber'],
    displayName: json['displayName'],
    createdAt: DateTime.parse(json['createdAt']),
    currentTreeId: json['currentTreeId'],
    partnerId: json['partnerId'],
  );

  factory UserModel.create(String phoneNumber) => UserModel(
    id: const Uuid().v4(),
    phoneNumber: phoneNumber,
    createdAt: DateTime.now(),
  );
}