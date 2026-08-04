import 'package:flutter/material.dart';

class CategoryStyle {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  const CategoryStyle(
    this.name,
    this.backgroundColor,
    this.textColor,
  );
}

const List<CategoryStyle> categoryStyles = [
  CategoryStyle('식비', Color(0xFFF2C9D6), Color(0xFF6A1E3B)),
  CategoryStyle('배달', Color(0xFFF2E1CF), Color(0xFF7A3D00)),
  CategoryStyle('생필품', Color(0xFFE1D6F2), Color(0xFF3F2A73)),
  CategoryStyle('교통비', Color(0xFFD2E2F2), Color(0xFF1D4C6A)),
  CategoryStyle('의료', Color(0xFFD8E8C3), Color(0xFF2E4D18)),
  CategoryStyle('문화', Color(0xFFF2D2D2), Color(0xFF6A1D1D)),
  CategoryStyle('경조사', Color(0xFFE2C2D8), Color(0xFF5A2146)),
  CategoryStyle('쇼핑', Color(0xFFEFEBC3), Color(0xFF6B6311)),
  CategoryStyle('기타', Color(0xFFCACACA), Color(0xFF2B2B2B)),
];

CategoryStyle getCategoryStyle(String category) {
  return categoryStyles.firstWhere(
    (item) => item.name == category,
    orElse: () => const CategoryStyle(
      '기타',
      Color(0xFFCACACA),
      Color(0xFF2B2B2B),
    ),
  );
}