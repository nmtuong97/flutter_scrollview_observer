import 'package:flutter/material.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/helper/chat_data_helper.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/model/chat_model.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/widget/chat_item_widget.dart';

import '../../../../list_infinite_scroll_observer.dart';

class ChatPageInfiniteScroll extends StatefulWidget {
  const ChatPageInfiniteScroll({Key? key}) : super(key: key);

  @override
  State<ChatPageInfiniteScroll> createState() => _ChatPageInfiniteScrollState();
}

class _ChatPageInfiniteScrollState extends State<ChatPageInfiniteScroll>
    with WidgetsBindingObserver {
  final GlobalKey<ListInfiniteScrollObserverState<ChatModel>> _listObserverKey =
      GlobalKey();

  bool editViewReadOnly = false;
  TextEditingController editViewController = TextEditingController();
  bool isShowClassicHeaderAndFooter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    editViewController.dispose();
    super.dispose();
  }

  Future<List<ChatModel>> _fetchPage(int pageKey) async {
    await Future.delayed(const Duration(seconds: 2));
    return Iterable<int>.generate(10)
        .map((e) => ChatDataHelper.createChatModel())
        .toList();
  }

  Widget _buildEditView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              minLines: 1,
              showCursor: true,
              readOnly: editViewReadOnly,
              controller: editViewController,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            iconSize: 24,
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightForFinite(),
            onPressed: () {
              setState(() {
                editViewReadOnly = !editViewReadOnly;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 100, 100, 100),
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: const Color.fromARGB(255, 19, 19, 19),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isShowClassicHeaderAndFooter = !isShowClassicHeaderAndFooter;
              });
            },
            child: Text(
              isShowClassicHeaderAndFooter ? "Classic" : "Material",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          IconButton(
            onPressed: () {
              editViewController.text = '';
              // Thêm tin nhắn mới qua phương thức addItems của ListInfiniteScrollObserver
              _listObserverKey.currentState
                  ?.addItems([ChatDataHelper.createChatModel()]);
            },
            icon: const Icon(Icons.add_comment),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListInfiniteScrollObserver<ChatModel>(
              key: _listObserverKey,
              onPageRequest: _fetchPage,
              getId: (chatModel) => chatModel.messageId,
              itemBuilder: (context, chatModel, index, totalCount) {
                return ChatItemWidget(
                  chatModel: chatModel,
                  index: index,
                  itemCount: totalCount,
                  onRemove: () {
                    // Xử lý xóa nếu cần.
                  },
                );
              },
            ),
          ),
          _buildEditView(),
          const SafeArea(top: false, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
