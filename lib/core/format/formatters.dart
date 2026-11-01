String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

String formatCategory(String category) {
  if (category.trim().isEmpty) {
    return 'General';
  }
  return category
      .split('-')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
