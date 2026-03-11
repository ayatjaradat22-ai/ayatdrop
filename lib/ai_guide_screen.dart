import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:easy_localization/easy_localization.dart';

class AiGuideScreen extends StatefulWidget {
  const AiGuideScreen({super.key});

  @override
  State<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends State<AiGuideScreen> {
  final TextEditingController _messageController = TextEditingController();
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool _isTyping = false;

  static const Color dropRed = Color(0xFFFF1111);

  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // استخدام flash-1.5 مع API Key الحالي
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyBPDzMixexTwMF7UYX_clJjSmTkCRoWodQ',
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || currentUser == null) return;

    final userMessage = text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser!.uid)
        .collection('messages')
        .add({
      'text': userMessage,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isTyping = true);

    try {
      final content = [Content.text("ai_prompt_prefix".tr() + " " + userMessage)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(currentUser!.uid)
            .collection('messages')
            .add({
          'text': response.text!,
          'sender': 'ai',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Detailed Gemini Error: $e");
      
      String errorMsg = e.toString();
      if (errorMsg.contains("API key not valid")) {
        errorMsg = "API Key is invalid. Please check Google AI Studio.";
      } else if (errorMsg.contains("location not supported")) {
        errorMsg = "Gemini is not supported in your current region/VPN.";
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(currentUser!.uid)
          .collection('messages')
          .add({
        'text': "DEBUG V4 ERROR: $errorMsg", 
        'sender': 'ai',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: dropRed, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text("${"ai_title".tr()} V4",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(currentUser?.uid)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: dropRed));
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildChatBubble(data['text'] ?? "", data['sender'] == 'user');
                  },
                );
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? dropRed : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Text("ai_typing_indicator".tr(), style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(hintText: "ai_input_hint".tr(), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: dropRed, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
