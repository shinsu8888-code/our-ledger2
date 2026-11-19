import 'package:flutter/material.dart';

/// 카테고리 정의 (지출/수입)
class CategoryDef {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryDef(this.name, this.icon, this.color);
}

const List<CategoryDef> expenseCategories = [
  CategoryDef('식비', Icons.restaurant, Color(0xFFEF6C00)),
  CategoryDef('카페/간식', Icons.local_cafe, Color(0xFF8D6E63)),
  CategoryDef('교통/차량', Icons.directions_car, Color(0xFF1976D2)),
  CategoryDef('주거/관리비', Icons.home, Color(0xFF00897B)),
  CategoryDef('의료/건강', Icons.local_hospital, Color(0xFFE53935)),
  CategoryDef('생활/마트', Icons.shopping_cart, Color(0xFF43A047)),
  CategoryDef('교육/자녀', Icons.school, Color(0xFF5E35B1)),
  CategoryDef('문화/여가', Icons.movie, Color(0xFFD81B60)),
  CategoryDef('패션/미용', Icons.checkroom, Color(0xFF7B1FA2)),
  CategoryDef('경조사/선물', Icons.card_giftcard, Color(0xFFF4511E)),
  CategoryDef('구독/통신', Icons.subscriptions, Color(0xFF0288D1)),
  CategoryDef('기타 지출', Icons.more_horiz, Color(0xFF607D8B)),
];

const List<CategoryDef> incomeCategories = [
  CategoryDef('급여', Icons.payments, Color(0xFF2E7D32)),
  CategoryDef('상여금', Icons.emoji_events, Color(0xFFF9A825)),
  CategoryDef('부수입', Icons.trending_up, Color(0xFF0277BD)),
  CategoryDef('기타 수입', Icons.more_horiz, Color(0xFF607D8B)),
];

CategoryDef categoryOf(String name, bool isIncome) {
  final list = isIncome ? incomeCategories : expenseCategories;
  for (final c in list) {
    if (c.name == name) return c;
  }
  return CategoryDef(name, Icons.receipt_long, const Color(0xFF607D8B));
}
