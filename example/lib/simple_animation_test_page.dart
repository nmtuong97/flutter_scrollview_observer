import 'package:flutter/material.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/helper/chat_data_helper.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/model/chat_model.dart';
import 'package:scrollview_observer_example/features/scene/chat_demo/widget/chat_item_widget.dart';

class SimpleAnimationTestPage extends StatefulWidget {
  @override
  _SimpleAnimationTestPageState createState() =>
      _SimpleAnimationTestPageState();
}

class _SimpleAnimationTestPageState extends State<SimpleAnimationTestPage> {
  List<ChatModel> staticChatList = [ChatDataHelper.createChatModel()];
  Map<String, bool> animatedItemSimple = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Simple Animation Test')),
      body: ListView.builder(
        reverse: true, // Keep reverse to test if it is related
        itemCount: staticChatList.length,
        itemBuilder: (context, index) {
          return _buildSimpleChatItem(staticChatList[index], index);
        },
      ),
    );
  }

  Widget _buildSimpleChatItem(ChatModel chatModel, int index) {
    bool isAnimatedSimple = animatedItemSimple[chatModel.messageId] ?? false;

    if (isAnimatedSimple) {
      return ChatItemWidget(
        chatModel: chatModel,
        index: index,
        itemCount: staticChatList.length,
        onRemove: () {}, // Dummy onRemove
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      // Increase duration for better visual
      curve: Curves.easeInOut,
      builder: (BuildContext context, double opacity, Widget? child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(
              'Simple Animation Builder (Frame): ${chatModel.messageId}, opacity: $opacity');
        });
        return Opacity(
          opacity: opacity,
          child: ChatItemWidget(
            chatModel: chatModel,
            index: index,
            itemCount: staticChatList.length,
            onRemove: () {}, // Dummy onRemove
          ),
        );
      },
      onEnd: () {
        animatedItemSimple[chatModel.messageId] = true;
        print('Simple Animation Ended: ${chatModel.messageId}');
      },
    );
  }
}
