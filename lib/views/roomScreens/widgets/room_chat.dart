import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';

class RoomChat extends StatefulWidget {
  final String roomId;

  const RoomChat({Key? key, required this.roomId}) : super(key: key);

  @override
  State<RoomChat> createState() => _RoomChatState();
}

class _RoomChatState extends State<RoomChat> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    try {
      if (_messageController.text.trim().isEmpty) return;

      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        Get.snackbar('Error', 'You must be logged in to send messages');
        return;
      }

      await _chatService.sendMessage(
        roomId: widget.roomId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Anonymous',
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUser = _authService.getCurrentUser();
                    final isMe = currentUser?.uid == message.senderId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message.senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 