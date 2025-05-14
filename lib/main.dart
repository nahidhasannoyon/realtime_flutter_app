import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // Replace with your real values
  static const _host = '192.168.0.109';
  static const _port = 8080;
  static const _token = 'YOUR_SECURE_TOKEN';
  static const _jwt = 'YOUR_JWT_TOKEN';
  // Use your actual server IP address.  Do NOT use localhost unless
  // the server is running on the *same* device as the Flutter app.
  // For a real mobile device, you need the network IP of your computer.
  // final channel = WebSocketChannel.connect(
  //   Uri.parse('ws://192.168.0.109:8080'), // Replace with your server's IP
  // );

  // Build your ws:// URI with query params and custom headers
  final WebSocketChannel channel = IOWebSocketChannel.connect(
    Uri(
      scheme: 'ws', 
      host: _host,
      port: _port,
      queryParameters: {
        'token': _token,
      },
    ),
    headers: {
      'Authorization': 'Bearer $_jwt',
      'X-API-KEY': 'your_api_key_here',
    },
  );

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatPage(channel: channel),
    );
  }
}

class ChatPage extends StatefulWidget {
  final WebSocketChannel channel;

  const ChatPage({super.key, required this.channel});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final List<String> _messages = []; // Store received messages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: widget.channel.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  //Added to show all messages
                  _messages.add(snapshot.data.toString());
                }
                return ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ListTile(
                      title: Text(
                        message,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final text = _controller.text;
                    if (text.isNotEmpty) {
                      widget.channel.sink.add(text);
                      _controller.clear();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _controller.dispose(); // Dispose the controller
    super.dispose();
  }
}
