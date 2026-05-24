import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/debounce_throttle.dart';

/// Search UI state with debouncing support
class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.isSearching = false,
    this.searchError,
  });

  final String query;
  final bool isSearching;
  final String? searchError;

  SearchUiState copyWith({
    String? query,
    bool? isSearching,
    String? searchError,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      searchError: searchError,
    );
  }
}

class SearchUiController extends StateNotifier<SearchUiState> {
  SearchUiController() : super(const SearchUiState());

  late Debouncer _debouncer;
  final Duration debounceDuration = const Duration(milliseconds: 500);

  /// Update search query with debouncing
  /// The search is only executed after [debounceDuration] has passed without new input
  void updateQuery(String value, {void Function()? onSearch}) {
    state = state.copyWith(query: value, isSearching: false);
    
    // Cancel previous debounce
    _debouncer.cancel();
    
    // Debounce the search
    _debouncer = Debouncer(
      delay: debounceDuration,
      onDebounce: () {
        onSearch?.call();
      },
    );
    
    _debouncer.call();
  }

  /// Clear search query immediately
  void clearQuery() {
    _debouncer.cancel();
    state = const SearchUiState();
  }

  /// Dispose the debouncer
  @override
  void dispose() {
    _debouncer.cancel();
    super.dispose();
  }
}

// Provider for search UI state with debouncing
final searchUiControllerProvider =
    StateNotifierProvider<SearchUiController, SearchUiState>(
  (ref) => SearchUiController(),
);
