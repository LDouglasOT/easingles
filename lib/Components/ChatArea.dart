import 'package:flutter/material.dart';

class ChatArea extends StatefulWidget {
  final void Function(String) onSend;

  ChatArea({required this.onSend});

  @override
  _ChatAreaState createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  TextEditingController _textController = TextEditingController();
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          // Display the record button or send button based on the text input
          _isRecording
              ? IconButton(
                  icon: Icon(Icons.mic, color: Colors.blue),
                  onPressed: () {
                    // Handle recording logic
                  },
                )
              : IconButton(
                  icon: Icon(Icons.send, color: _textController.text.isEmpty ? Colors.grey : Colors.blue),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      // Send the message
                      widget.onSend(_textController.text);
                      _textController.clear();
                    }
                  },
                ),
          Expanded(
            child: TextField(
              controller: _textController,
              onChanged: (text) {
                // Update the UI when text is entered
                setState(() {
                  _isRecording = text.isEmpty;
                });
              },
              decoration: InputDecoration.collapsed(
                hintText: "Type a message",
              ),
            ),
          ),
          InkWell(
            child: Icon(
              Icons.camera_alt,
              color: Colors.green,
              size: 24,
            ),
            onTap: () {
              // Handle camera tap
            },
          ),
        ],
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: Scaffold(
//       appBar: AppBar(title: Text("Message Bar Example")),
//       body: Column(
//         children: [
//           Expanded(child: Container()), // Add your chat display here
//           ChatArea(
//             onSend: (message) {
//               print("Sending message: $message");
//               // Add logic to send the message
//             },
//           ),
//         ],
//       ),
//     ),
//   ));
// }
