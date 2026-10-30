import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_task/core/network/api_exception.dart';
import 'package:test_task/features/products/data/product_repository.dart';
import 'package:test_task/features/products/domain/product.dart';

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.total = 0,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final List<Product> products;
  final int total;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreError;

  bool get hasMore => products.length < total;

  bool get isEmpty =>
      !isInitialLoading && errorMessage == null && products.isEmpty;

  ProductsState copyWith({
    List<Product>? products,
    int? total,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      total: total ?? this.total,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}

final productsControllerProvider =
    NotifierProvider<ProductsController, ProductsState>(ProductsController.new);

class ProductsController extends Notifier<ProductsState> {
  int _requestId = 0;

  @override
  ProductsState build() {
    Future.microtask(loadInitial);
    return const ProductsState(isInitialLoading: true);
  }

  Future<void> loadInitial() async {
    final requestId = ++_requestId;
    state = const ProductsState(isInitialLoading: true);
    try {
      final page = await ref
          .read(productRepositoryProvider)
          .fetchProducts(skip: 0);
      if (!ref.mounted || requestId != _requestId) return;
      state = ProductsState(products: page.products, total: page.total);
    } on ApiException catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      state = ProductsState(errorMessage: error.message);
    }
  }

  /// Returns an error message when refresh fails and the current list is kept.
  Future<String?> refresh() async {
    final requestId = ++_requestId;
    try {
      final page = await ref
          .read(productRepositoryProvider)
          .fetchProducts(skip: 0);
      if (!ref.mounted || requestId != _requestId) return null;
      state = ProductsState(products: page.products, total: page.total);
      return null;
    } on ApiException catch (error) {
      if (!ref.mounted || requestId != _requestId) return null;
      if (state.products.isEmpty) {
        state = ProductsState(errorMessage: error.message);
        return null;
      }
      return error.message;
    }
  }

  Future<void> loadMore({bool userInitiated = false}) async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    if (state.loadMoreError != null && !userInitiated) return;

    final requestId = _requestId;
    final skip = state.products.length;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    try {
      final page = await ref
          .read(productRepositoryProvider)
          .fetchProducts(skip: skip);
      if (!ref.mounted || requestId != _requestId) return;

      final ids = state.products.map((product) => product.id).toSet();
      final merged = [
        ...state.products,
        ...page.products.where((product) => ids.add(product.id)),
      ];
      state = state.copyWith(
        products: merged,
        total: page.total,
        isLoadingMore: false,
      );
    } on ApiException catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: error.message,
      );
    }
  }
}
