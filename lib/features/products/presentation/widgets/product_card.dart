import 'package:flutter/material.dart';
import 'package:dummyjson_flutter_test/core/format/formatters.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    required this.dense,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: dense ? _denseLayout() : _gridLayout(),
      ),
    );
  }

  Widget _denseLayout() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Thumbnail(product: product, size: 96),
          const SizedBox(width: 12),
          Expanded(child: _Summary(product: product)),
        ],
      ),
    );
  }

  Widget _gridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Thumbnail(product: product)),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _Summary(product: product),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product, this.size});

  final Product product;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final image = Hero(
      tag: 'product-image-${product.id}',
      child: ProductImage(url: product.thumbnail),
    );
    if (size == null) {
      return image;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          formatCategory(product.category),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              formatPrice(product.price),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
            const SizedBox(width: 2),
            Text(
              product.rating.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
