/*
 * @Author: LinXunFeng linxunfeng@yeah.net
 * @Repo: https://github.com/LinXunFeng/flutter_scrollview_observer
 * @Date: 2022-09-25 21:41:13
 */

class ChatModel {
  ChatModel({
    required this.isOwn,
    required this.content,
    required this.messageId,
    this.hasAnimated = false,
  });

  final String messageId;
  final bool isOwn;
  final String content;
  bool hasAnimated;
}
