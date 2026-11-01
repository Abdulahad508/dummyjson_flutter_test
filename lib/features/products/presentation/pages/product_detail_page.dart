import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/format/formatters.dart';
import 'package:dummyjson_flutter_test/core/widgets/status_views.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/widgets/product_image.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailBloc, ProductDetailState>(
      builder: (context, state) {
        final showAppBar = state.status != ProductDetailStatus.success;
        return Scaffold(
          appBar: showAppBar ? AppBar() : null,
          body: switch (state.status) {
            ProductDetailStatus.initial || ProductDetailStatus.loading =>
              const LoadingView(message: 'Loading product...'),
            ProductDetailStatus.failure => ErrorView(
              message: state.errorMessage ?? 'Could not load this product.',
              onRetry: () {
                context.read<ProductDetailBloc>().add(
                  ProductDetailRequested(productId),
                );
              },
            ),
            ProductDetailStatus.success => _DetailBody(product: state.product!),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 320,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'product-image-${product.id}',
              child: _Gallery(urls: product.gallery),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand ?? formatCategory(product.category),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(product.title, style: theme.textTheme.headlineSmall),
                if (product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatCategory(product.category),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatPrice(product.price),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.discountPercentage >= 1)
                      _Pill(
                        label:
                            '${product.discountPercentage.toStringAsFixed(0)}% off',
                        color: scheme.primary,
                      ),
                    _Pill(
                      label: product.availabilityStatus,
                      color: _availabilityColor(product.availabilityStatus),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(product.rating.toStringAsFixed(1)),
                    Text(
                      '  ·  ${product.stock} in stock',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('About', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(product.description, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _availabilityColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('out')) {
      return const Color(0xFFB3261E);
    }
    if (normalized.contains('low')) {
      return const Color(0xFFB26A00);
    }
    return const Color(0xFF0F7B4C);
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.urls});

  final List<String> urls;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE7EEEC),
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, size: 48),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.urls.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) {
            return ProductImage(url: widget.urls[index]);
          },
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x66000000)],
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
