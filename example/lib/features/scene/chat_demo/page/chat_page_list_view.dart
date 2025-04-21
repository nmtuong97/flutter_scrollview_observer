import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/widget/chat_unread_tip_view.dart';
import 'package:scrollview_observer_example/utils/random.dart';

// Các sự kiện của Chat
abstract class ChatEvent {}

class LoadInitialMessages extends ChatEvent {}

class FetchPage extends ChatEvent {
  final int pageKey;

  FetchPage(this.pageKey);
}

class ToggleHeaderFooterStyle extends ChatEvent {}

class ToggleEditReadOnly extends ChatEvent {}

class AddMessage extends ChatEvent {
  final int count;

  AddMessage(this.count);
}

class ClearInputAndAddMessage extends ChatEvent {}

class UpdateUnreadMsgCount extends ChatEvent {
  final bool isReset;
  final int changeCount;

  UpdateUnreadMsgCount({this.isReset = false, this.changeCount = 1});
}

class AddUnreadTipView extends ChatEvent {}

class ChatState<T> {
  final bool needIncrementUnreadMsgCount;
  final bool editViewReadOnly;
  final bool isLoading;
  final List<T>? messages;
  final int unreadMsgCount;
  final String? error;
  final bool showUnreadTip;

  ChatState({
    this.needIncrementUnreadMsgCount = false,
    this.editViewReadOnly = false,
    this.isLoading = false,
    this.messages,
    this.unreadMsgCount = 0,
    this.error,
    this.showUnreadTip = false,
  });

  ChatState<T> copyWith({
    bool? needIncrementUnreadMsgCount,
    bool? editViewReadOnly,
    bool? isLoading,
    List<T>? messages,
    int? unreadMsgCount,
    String? error,
    bool? showUnreadTip,
  }) {
    return ChatState<T>(
      needIncrementUnreadMsgCount:
          needIncrementUnreadMsgCount ?? this.needIncrementUnreadMsgCount,
      editViewReadOnly: editViewReadOnly ?? this.editViewReadOnly,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      unreadMsgCount: unreadMsgCount ?? this.unreadMsgCount,
      error: error ?? this.error,
      showUnreadTip: showUnreadTip ?? this.showUnreadTip,
    );
  }
}

class ChatPagedListView<T> extends StatefulWidget {
  final Widget Function(BuildContext, T, int) itemBuilder;
  final String Function(T)? itemKeyExtractor;
  final void Function(int)? onRemove;
  final List<T> Function({int num}) createItems;

  const ChatPagedListView({
    Key? key,
    required this.itemBuilder,
    required this.createItems,
    this.itemKeyExtractor,
    this.onRemove,
  }) : super(key: key);

  @override
  State<ChatPagedListView<T>> createState() => ChatPagedListViewState<T>();
}

class ChatPagedListViewState<T> extends State<ChatPagedListView<T>>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController scrollController = ScrollController();
  late ListObserverController observerController;
  late ChatScrollObserver chatObserver;
  final PagingController<int, T> pagingController =
      PagingController(firstPageKey: 0);
  final LayerLink layerLink = LayerLink();
  final ValueNotifier<int> unreadMsgCount = ValueNotifier<int>(0);
  final Map<String, bool> animatedItems = {};
  OverlayEntry? unreadTipOverlay;

  late ChatState<T> state;

  @override
  void didUpdateWidget(covariant ChatPagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget");
  }

  @override
  void initState() {
    super.initState();
    print("initState");
    WidgetsBinding.instance.addObserver(this);
    state = ChatState<T>(messages: []);

    scrollController.addListener(_scrollControllerListener);
    observerController = ListObserverController(controller: scrollController)
      ..cacheJumpIndexOffset = false;

    chatObserver = ChatScrollObserver(observerController)
      ..fixedPositionOffset = 5
      ..toRebuildScrollViewCallback = () {
        print('toRebuildScrollViewCallback');
        handleEvent(LoadInitialMessages());
      };
    chatObserver.onHandlePositionResultCallback = (result) {
      // print(
      //     "onHandlePositionResultCallback changeCount: ${result.changeCount}");
      // print("onHandlePositionResultCallback mode: ${result.mode}");
      // print("onHandlePositionResultCallback type: ${result.type}");

      if (!state.needIncrementUnreadMsgCount) return;
      switch (result.type) {
        case ChatScrollObserverHandlePositionType.keepPosition:
          handleEvent(UpdateUnreadMsgCount(changeCount: result.changeCount));
          break;
        case ChatScrollObserverHandlePositionType.none:
          handleEvent(UpdateUnreadMsgCount(isReset: true));
          break;
      }
    };

    pagingController
        .addPageRequestListener((pageKey) => handleEvent(FetchPage(pageKey)));

    handleEvent(LoadInitialMessages());
    Future.delayed(
        const Duration(seconds: 1), () => handleEvent(AddUnreadTipView()));
  }

  void handleEvent(ChatEvent event) {
    print("handleEvent:${event.runtimeType} ");
    if (event is LoadInitialMessages) {
      _onLoadInitialMessages(event);
    } else if (event is FetchPage) {
      _onFetchPage(event);
    } else if (event is ToggleEditReadOnly) {
      _onToggleEditReadOnly(event);
    } else if (event is AddMessage) {
      _onAddMessage(event);
    } else if (event is ClearInputAndAddMessage) {
      _onClearInputAndAddMessage(event);
    } else if (event is UpdateUnreadMsgCount) {
      _onUpdateUnreadMsgCount(event);
    } else if (event is AddUnreadTipView) {
      _onAddUnreadTipView(event);
    }
  }

  Future<void> _onLoadInitialMessages(LoadInitialMessages event) async {
    print("_onLoadInitialMessages: ");
    final initialMessages = widget.createItems(num: 10);
    setState(() {
      state = state.copyWith(messages: initialMessages);
      pagingController.itemList = initialMessages;
    });
  }

  Future<void> _onFetchPage(FetchPage event) async {
    print("_onFetchPage: ");
    setState(() => state = state.copyWith(isLoading: true));
    await Future.delayed(const Duration(seconds: 2));
    try {
      final newItems = widget.createItems(num: 10);
      final nextPageKey = event.pageKey + newItems.length;
      pagingController.appendPage(newItems, nextPageKey);
      setState(() => state = state.copyWith(
          messages: pagingController.itemList, isLoading: false));
    } catch (error) {
      pagingController.error = error;
      setState(() =>
          state = state.copyWith(error: error.toString(), isLoading: false));
    }
  }

  void _onToggleEditReadOnly(ToggleEditReadOnly event) {
    print("_onToggleEditReadOnly: ");
    setState(() =>
        state = state.copyWith(editViewReadOnly: !state.editViewReadOnly));
  }

  void _onAddMessage(AddMessage event) {
    print("_onAddMessage: ");
    chatObserver.standby(changeCount: event.count);
    pagingController.itemList?.insert(0, widget.createItems(num: 1).first);
    setState(() => state = state.copyWith(
          needIncrementUnreadMsgCount: true,
        ));
  }

  void _onClearInputAndAddMessage(ClearInputAndAddMessage event) {
    print("_onClearInputAndAddMessage: ");
    handleEvent(AddMessage(RandomTool.genInt(min: 1, max: 1)));
  }

  void _onUpdateUnreadMsgCount(UpdateUnreadMsgCount event) {
    print("_onUpdateUnreadMsgCount: ");
    final newCount =
        event.isReset ? 0 : state.unreadMsgCount + event.changeCount;
    unreadMsgCount.value = newCount;
    setState(() => state = state.copyWith(
        unreadMsgCount: newCount, needIncrementUnreadMsgCount: false));
  }

  void _onAddUnreadTipView(AddUnreadTipView event) {
    print("_onAddUnreadTipView: ");
    setState(() => state = state.copyWith(showUnreadTip: true));
    _addUnreadTipOverlay();
  }

  void _scrollControllerListener() {
    // print("_scrollControllerListener: ");
    if (scrollController.offset < 50) {
      handleEvent(UpdateUnreadMsgCount(isReset: true));
    }
  }

  void _addUnreadTipOverlay() {
    print("_addUnreadTipOverlay: ");
    unreadTipOverlay?.remove();
    unreadTipOverlay = OverlayEntry(
      builder: (_) => UnconstrainedBox(
        child: CompositedTransformFollower(
          link: layerLink,
          followerAnchor: Alignment.bottomRight,
          targetAnchor: Alignment.topRight,
          offset: const Offset(-20, 0),
          child: Material(
            type: MaterialType.transparency,
            child: ValueListenableBuilder<int>(
              valueListenable: unreadMsgCount,
              builder: (_, value, __) => ChatUnreadTipView(
                unreadMsgCount: value,
                onTap: () {
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  handleEvent(UpdateUnreadMsgCount(isReset: true));
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(unreadTipOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    print('PagedListView build: ${chatObserver.isShrinkWrap}');
    return Column(
      children: [
        Expanded(
          child: ListViewObserver(
            controller: observerController,
            child: Align(
              alignment: Alignment.topCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      PagedListView<int, T>(
                        pagingController: pagingController,
                        scrollController: scrollController,
                        shrinkWrap: chatObserver.isShrinkWrap,
                        builderDelegate: PagedChildBuilderDelegate<T>(
                          itemBuilder: (context, item, index) {
                            final itemKey = widget.itemKeyExtractor != null
                                ? widget.itemKeyExtractor!(item)
                                : index.toString();
                            final isAnimated = animatedItems[itemKey] ?? false;

                            if (!isAnimated) {
                              animatedItems[itemKey] = true;
                              return SlideTransition(
                                key: Key(itemKey),
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 1.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: AnimationController(
                                    duration: const Duration(milliseconds: 300),
                                    vsync: this,
                                  )..forward(),
                                  curve: Curves.easeInOut,
                                )),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(CurvedAnimation(
                                    parent: AnimationController(
                                      duration:
                                          const Duration(milliseconds: 500),
                                      vsync: this,
                                    )..forward(),
                                    curve: Curves.easeInOut,
                                  )),
                                  child:
                                      widget.itemBuilder(context, item, index),
                                ),
                              );
                            }
                            return widget.itemBuilder(context, item, index);
                          },
                        ),
                        reverse: true,
                        physics: chatObserver.isShrinkWrap
                            ? const NeverScrollableScrollPhysics()
                            : ChatObserverClampingScrollPhysics(
                                observer: chatObserver),
                        padding: const EdgeInsets.all(15),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        CompositedTransformTarget(link: layerLink, child: Container()),
      ],
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    pagingController.dispose();
    unreadTipOverlay?.remove();
    super.dispose();
  }
}
