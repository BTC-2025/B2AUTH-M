import 'package:flutter/material.dart';

class LinkedAppInfo {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final Color brandColor;
  final List<String> scopes;
  final String lastSync;
  bool isConnected;

  LinkedAppInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.brandColor,
    required this.scopes,
    required this.lastSync,
    this.isConnected = true,
  });
}
