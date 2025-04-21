import 'package:flutter/material.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/helper/chat_data_helper.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/model/chat_model.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/widget/chat_item_widget.dart';

import 'chat_page_list_view.dart'; // Điều chỉnh import theo tên file của bạn

class ChatPageInfinite extends StatefulWidget {
  const ChatPageInfinite({Key? key}) : super(key: key);

  @override
  State<ChatPageInfinite> createState() => _ChatPageInfiniteState();
}

class _ChatPageInfiniteState extends State<ChatPageInfinite> {
  final GlobalKey<ChatPagedListViewState<ChatModel>> _chatListKey =
      GlobalKey<ChatPagedListViewState<ChatModel>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 100, 100, 100),
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: const Color.fromARGB(255, 19, 19, 19),
        actions: [
          IconButton(
            onPressed: () => _chatListKey.currentState
                ?.handleEvent(ClearInputAndAddMessage()),
            icon: const Icon(Icons.add_comment),
          ),
        ],
      ),
      body: ChatPagedListView<ChatModel>(
        key: _chatListKey,
        itemBuilder: (context, chatModel, index) => ChatItemWidget(
          chatModel: chatModel,
          index: index,
          itemCount: _chatListKey.currentState?.state.messages?.length ?? 0,
        ),
        createItems: ({int num = 3}) => Iterable<int>.generate(num)
            .map((_) => ChatDataHelper.createChatModel())
            .toList(),
        itemKeyExtractor: (chatModel) => chatModel.messageId,
      ),
    );
  }
}
