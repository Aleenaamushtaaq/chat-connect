import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String? replyToMessage;
  final bool isRead;
  final bool isDeleted;
  final bool isPinned;
  final String searchQuery;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.replyToMessage,
    this.isRead = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.searchQuery = "",
  });

  @override
  Widget build(BuildContext context) {
    final Color senderColor = const Color(0xFF7C4DFF);
    final Color receiverColor = const Color(0xFF1B202D);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Pinned Icon
          if (isPinned && !isDeleted)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 2),
              child: Icon(Icons.push_pin, size: 12, color: Colors.white54),
            ),

          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Deleted message ka background transparent ya bohot light
              color: isDeleted ? Colors.white.withOpacity(0.05) : (isMe ? senderColor : receiverColor),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isMe ? 15 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 15),
              ),
              border: isDeleted ? Border.all(color: Colors.white10) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply UI (Sirf tab dikhao jab message delete na hua ho)
                if (replyToMessage != null && !isDeleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.reply, size: 14, color: Colors.white70),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            replyToMessage!,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message Text with Highlight
                isDeleted
                    ? const Text(
                  "🚫 This message was deleted",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
                    : RichText(
                  text: TextSpan(
                    children: _getHighlightedText(message, searchQuery),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 4),

                // Time and Blue Ticks
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                    // Blue ticks sirf tab jab message 'Me' ka ho aur delete na hua ho
                    if (isMe && !isDeleted) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: isRead ? const Color(0xFF40C4FF) : Colors.white38,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Highlight Helper
  List<TextSpan> _getHighlightedText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: text)];
    }
    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    int start = 0;
    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.amber.withOpacity(0.7),
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }
    return spans;
  }
}