import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

class ListInfiniteScrollObserver<T> extends StatefulWidget {
  final Future<List<T>> Function(int pageKey) onPageRequest;
  final List<T>? initialItems;
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    int totalCount,
  ) itemBuilder;
  final String Function(T item) getId;
  final EdgeInsets padding;
  final bool reverse;

  const ListInfiniteScrollObserver({
    Key? key,
    required this.onPageRequest,
    required this.itemBuilder,
    required this.getId,
    this.initialItems,
    this.padding = const EdgeInsets.only(
      left: 10,
      right: 10,
      top: 15,
      bottom: 15,
    ),
    this.reverse = true,
  }) : super(key: key);

  @override
  ListInfiniteScrollObserverState<T> createState() =>
      ListInfiniteScrollObserverState<T>();
}

class ListInfiniteScrollObserverState<T>
    extends State<ListInfiniteScrollObserver<T>>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final ScrollController _scrollController;
  late final ListObserverController _observerController;
  late final ChatScrollObserver chatObserver;
  late final PagingController<int, T> _pagingController;
  final Map<String, bool> _animatedItem = {};

  final ValueNotifier<int> unreadMsgCount = ValueNotifier<int>(0);
  bool needIncrementUnreadMsgCount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollControllerListener);

    _observerController = ListObserverController(controller: _scrollController)
      ..cacheJumpIndexOffset = false;

    // Khởi tạo chatObserver và gán callback riêng
    chatObserver = ChatScrollObserver(_observerController)
      ..fixedPositionOffset = 5
      ..toRebuildScrollViewCallback = () => setState(() {});
    chatObserver.onHandlePositionResultCallback = (result) {
      if (!needIncrementUnreadMsgCount) return;
      switch (result.type) {
        case ChatScrollObserverHandlePositionType.keepPosition:
          _updateUnreadMsgCount(changeCount: result.changeCount);
          break;
        case ChatScrollObserverHandlePositionType.none:
          _updateUnreadMsgCount(isReset: true);
          break;
      }
    };

    _pagingController = PagingController(firstPageKey: 0);
    _pagingController.addPageRequestListener((pageKey) async {
      try {
        final newItems = await widget.onPageRequest(pageKey);
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      } catch (error) {
        _pagingController.error = error;
      }
    });

    if (widget.initialItems != null) {
      _pagingController.itemList = widget.initialItems;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    chatObserver.observeSwitchShrinkWrap();
    // In log để kiểm tra giá trị isShrinkWrap
    // print("isShrinkWrap: ${chatObserver.isShrinkWrap}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.of(context).viewInsets.bottom != 0) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollControllerListener);
    _scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void _scrollControllerListener() {
    if (_scrollController.offset < 50) {
      _updateUnreadMsgCount(isReset: true);
    }
  }

  void _updateUnreadMsgCount({bool isReset = false, int changeCount = 1}) {
    needIncrementUnreadMsgCount = false;
    unreadMsgCount.value = isReset ? 0 : unreadMsgCount.value + changeCount;
  }

  void addItems(List<T> newItems) {
    // Báo cho chatObserver giữ vị trí trước khi thêm item
    chatObserver.standby(changeCount: newItems.length);
    setState(() {
      needIncrementUnreadMsgCount = true;
      _pagingController.itemList?.insertAll(0, newItems);
    });
  }

  ValueNotifier<int> get unreadCountNotifier => unreadMsgCount;

  Widget _buildItem(BuildContext context, T item, int index) {
    bool isAnimated = _animatedItem[widget.getId(item)] ?? false;
    Widget child = widget.itemBuilder(
      context,
      item,
      index,
      _pagingController.itemList?.length ?? 0,
    );
    if (!isAnimated) {
      _animatedItem[widget.getId(item)] = true;
      final slideController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      )..forward();
      final fadeController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      )..forward();
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: slideController,
          curve: Curves.easeInOut,
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: fadeController,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
      );
    } else {
      return child;
    }
  }

  Widget _buildListView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PagedListView<int, T>(
          pagingController: _pagingController,
          scrollController: _scrollController,
          // Giả sử khi isShrinkWrap là false (tức có đủ chiều cao), ta cho phép cuộn
          shrinkWrap: !chatObserver.isShrinkWrap,
          builderDelegate: PagedChildBuilderDelegate<T>(
            itemBuilder: (context, item, index) =>
                _buildItem(context, item, index),
          ),
          reverse: widget.reverse,
          physics: ChatObserverClampingScrollPhysics(observer: chatObserver),
          padding: widget.padding,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListViewObserver(
      controller: _observerController,
      child: _buildListView(),
    );
  }
}
