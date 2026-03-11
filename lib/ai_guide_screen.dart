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
  final ScrollController _scrollController = ScrollController();
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool _isTyping = false;

  static const Color dropRed = Color(0xFFFF1111);

  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyBPDzMixexTwMF7UYX_clJjSmTkCRoWodQ',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(currentUser!.uid)
          .collection('messages')
          .add({
        'text': "DEBUG V5 ERROR: $e", 
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
            Text("ai_title".tr(),
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
                
                if (docs.isEmpty) {
                  return _buildWelcomeState();
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
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
          _buildSuggestionsRow(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 15),
          Text("ai_no_messages".tr(), style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    final List<String> suggestions = [
      "ai_sugg_budget".tr(),
      "ai_sugg_coffee".tr(),
      "ai_sugg_nearby".tr(),
    ];

    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(suggestions[index], style: const TextStyle(fontSize: 13, color: Colors.black87)),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Colors.grey.shade200),
              onPressed: () => _sendMessage(suggestions[index]),
            ),
          );
        },
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
