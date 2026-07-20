import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';

import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';

import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/l10n/tr.dart';

import 'package:optombai/widgets/utils/fields/search_result_card.dart';
import 'package:optombai/widgets/utils/fields/user_search_result_card.dart';

sealed class _SearchHit {
  const _SearchHit();
}

class _ProductHit extends _SearchHit {
  final Product product;
  const _ProductHit(this.product);
}

class _UserHit extends _SearchHit {
  final User user;
  const _UserHit(this.user);
}

class CustomSearchField extends StatefulWidget {
  final InputBorder? focusBorder;
  final Function(String)? onChange;
  final void Function(String query)? onSubmit;

  final int maxUsers;
  final int maxProducts;

  const CustomSearchField({
    super.key,
    this.focusBorder,
    this.onChange,
    this.onSubmit,
    this.maxUsers = 5,
    this.maxProducts = 7,
  });

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Product> _productResults = [];
  List<User> _userResults = [];

  bool _showSuggestions = false;

  bool _isSearchingProducts = false;
  bool _isSearchingUsers = false;

  Timer? _debounce;

  String _normalizeQuery(String q) {
    final query = q.trim().toLowerCase();
    if (query == 'подама') return 'помада';
    return q.trim();
  }

  void _clearResults() {
    setState(() {
      _productResults = [];
      _userResults = [];
      _showSuggestions = false;
      _isSearchingProducts = false;
      _isSearchingUsers = false;
    });
  }

  void _onTextChanged(String raw) {
    final q = _normalizeQuery(raw);
    widget.onChange?.call(q);

    if (q.isEmpty) {
      _debounce?.cancel();
      _clearResults();
      return;
    }

    setState(() {
      _showSuggestions = true;
      _isSearchingProducts = true;
      _isSearchingUsers = true;
    });

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      context.read<ProductBloc>().add(ProductWithFilter(search: q));
      context.read<UserBloc>().add(
            SearchUsersEvent(
              search: q,
              page: 1,
              limit: 20,
            ),
          );
    });
  }

  void _submitSearch() {
    final q = _normalizeQuery(_controller.text);
    if (q.isEmpty) return;

    _focusNode.unfocus();
    setState(() => _showSuggestions = false);

    if (widget.onSubmit != null) {
      widget.onSubmit!(q);
      return;
    }

    context.router.push(ResultsRoute(initialSearch: q));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_SearchHit> get _mixedHits {
    final users = _userResults.take(widget.maxUsers).map(_UserHit.new);
    final products =
        _productResults.take(widget.maxProducts).map(_ProductHit.new);

    return [
      ...users,
      ...products,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    final bg = isDarkMode ? Colors.black : Colors.white;
    final border = isDarkMode ? Colors.white12 : Colors.grey.shade300;
    final hintColor = isDarkMode ? Colors.white60 : const Color(0xff797979);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white70 : const Color(0xff797979);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state.isLoading) {
              setState(() => _isSearchingProducts = true);
              return;
            }

            if (state.isSuccess) {
              setState(() {
                _productResults = state.products;
                _isSearchingProducts = false;
              });
              return;
            }

            if (state.errors.isNotEmpty) {
              setState(() {
                _productResults = [];
                _isSearchingProducts = false;
              });
            }
          },
        ),
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state.isLoading) {
              setState(() => _isSearchingUsers = true);
              return;
            }

            if (state.isSuccess) {
              setState(() {
                _userResults = state.notifications;
                _isSearchingUsers = false;
              });
              return;
            }

            if (state.errors.isNotEmpty) {
              setState(() {
                _userResults = [];
                _isSearchingUsers = false;
              });
            }
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            style: TextStyle(color: textColor),
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSubmitted: (_) => _submitSearch(),
            decoration: InputDecoration(
              filled: true,
              fillColor: bg,
              hintText: tr(context, 'search_hint'),
              hintStyle: TextStyle(
                fontSize: 11.sp,
                color: hintColor,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.search, color: iconColor),
              suffixIcon: _controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: _submitSearch,
                      icon: const Icon(Icons.search),
                      color: const Color(0xFF1967FF),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(width: 0.7.w, color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: BorderSide(width: 0.7.w, color: border),
              ),
              focusedBorder: widget.focusBorder ??
                  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Color(0xFF1967FF)),
                  ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: BoxConstraints(maxHeight: 300.h),
              child: _SearchSuggestionsList(
                hits: _mixedHits,
                isSearchingUsers: _isSearchingUsers,
                isSearchingProducts: _isSearchingProducts,
                hasUserResults: _userResults.isNotEmpty,
                hasProductResults: _productResults.isNotEmpty,
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSuggestionsList extends StatelessWidget {
  final List<_SearchHit> hits;
  final bool isSearchingUsers;
  final bool isSearchingProducts;
  final bool hasUserResults;
  final bool hasProductResults;

  const _SearchSuggestionsList({
    required this.hits,
    required this.isSearchingUsers,
    required this.isSearchingProducts,
    required this.hasUserResults,
    required this.hasProductResults,
  });

  @override
  Widget build(BuildContext context) {
    final showLoading = ((isSearchingUsers && !hasUserResults) ||
            (isSearchingProducts && !hasProductResults)) &&
        hits.isEmpty;

    if (showLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Text(tr(context, 'search_loading')),
          ],
        ),
      );
    }

    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(tr(context, 'search_empty')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: hits.length,
      itemBuilder: (context, index) {
        final h = hits[index];
        if (h is _UserHit) return UserSearchResultCard(user: h.user);
        if (h is _ProductHit) return SearchResultCard(product: h.product);
        return const SizedBox.shrink();
      },
    );
  }
}
