import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dummyjson_flutter_test/core/widgets/status_views.dart';
import 'package:dummyjson_flutter_test/features/products/domain/entities/product.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:dummyjson_flutter_test/features/products/presentation/widgets/product_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    required this.onProductTap,
    this.userName,
    this.onLogout,
    super.key,
  });

  final ValueChanged<Product> onProductTap;
  final String? userName;
  final VoidCallback? onLogout;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      context.read<ProductListBloc>().add(const ProductListLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<ProductListBloc>();
    final done = bloc.stream.firstWhere(
      (state) =>
          !state.isRefreshing && state.status != ProductListStatus.loading,
    );
    bloc.add(const ProductListRefreshed());
    try {
      await done.timeout(const Duration(seconds: 20));
    } catch (_) {
      // The indicator should not spin forever if the bloc is disposed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          if (name != null && name.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(name),
              ),
            ),
          if (widget.onLogout != null)
            IconButton(
              key: const Key('logoutButton'),
              tooltip: 'Log out',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: BlocListener<ProductListBloc, ProductListState>(
        listenWhen: (previous, current) {
          return current.errorMessage != null &&
              current.errorMessage != previous.errorMessage &&
              current.products.isNotEmpty;
        },
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        child: BlocListener<ProductListBloc, ProductListState>(
          listenWhen: (previous, current) {
            return previous.products.length != current.products.length ||
                previous.isLoadingMore != current.isLoadingMore;
          },
          listener: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _maybeLoadMore();
              }
            });
          },
          child: BlocBuilder<ProductListBloc, ProductListState>(
            builder: (context, state) => _buildBody(state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ProductListState state) {
    if (state.products.isEmpty &&
        (state.status == ProductListStatus.initial ||
            state.status == ProductListStatus.loading)) {
      return const LoadingView(message: 'Loading products...');
    }
    if (state.status == ProductListStatus.failure && state.products.isEmpty) {
      return _scrollableStatus(
        ErrorView(
          message: state.errorMessage ?? 'Could not load products.',
          onRetry: () {
            context.read<ProductListBloc>().add(const ProductListStarted());
          },
        ),
      );
    }
    if (state.status == ProductListStatus.success && state.products.isEmpty) {
      return _scrollableStatus(
        const EmptyView(
          title: 'No products',
          message: 'There is nothing to show right now. Pull to refresh.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        final dense = columns == 1;
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: dense ? 136 : 308,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      dense: dense,
                      onTap: () => widget.onProductTap(product),
                    );
                  }, childCount: state.products.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    children: [
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: CircularProgressIndicator(),
                        ),
                      Text(
                        state.hasReachedMax
                            ? 'Showing all ${state.total} products'
                            : 'Showing ${state.products.length} of ${state.total}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scrollableStatus(Widget child) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: constraints.maxHeight, child: child)],
          );
        },
      ),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1100) {
      return 3;
    }
    if (width >= 720) {
      return 2;
    }
    return 1;
  }
}
