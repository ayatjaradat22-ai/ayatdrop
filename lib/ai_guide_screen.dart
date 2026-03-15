import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'premium.dart';

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
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAndAnalyzeImage(bool isPremium) async {
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    _sendImageMessage(bytes);
  }

  Future<void> _sendImageMessage(Uint8List imageBytes) async {
    setState(() => _isTyping = true);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser!.uid)
        .collection('messages')
        .add({
      'text': "📸 [Analyzing Image...]",
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    try {
      final prompt = TextPart("ai_prompt_prefix".tr() + " " + "Analyze this image and find if there are any related deals or stores in our Drop app. ONLY respond if it relates to shopping, prices, or Jordan deals.");
      final imagePart = DataPart('image/jpeg', imageBytes);
      
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null) {
        await _saveAiResponse(response.text!);
      }
    } catch (e) {
      _saveAiResponse("Sorry, I couldn't analyze the image right now.");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
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
      final systemStrictPrompt = "IMPORTANT: You are the 'Drop App' assistant. You MUST NOT answer any questions unrelated to shopping, deals, discounts, store locations in Jordan, or app features. If the user asks something else (like math, history, coding), politely refuse and say you only help with deals. User Question: ";
      
      final content = [Content.text(systemStrictPrompt + userMessage)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        await _saveAiResponse(response.text!);
      }
    } catch (e) {
      _saveAiResponse("Error connecting to server. Please try again.");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _saveAiResponse(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(currentUser!.uid)
        .collection('messages')
        .add({
      'text': text,
      'sender': 'ai',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 10),
            Text("premium_feature".tr()),
          ],
        ),
        content: Text("visual_search_desc".tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cancel_button".tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dropRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
            },
            child: Text("upgrade_now".tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, userSnapshot) {
        bool isPremium = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          isPremium = userData?['isPremium'] ?? false;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 20)),
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
                    
                    if (docs.isEmpty) return _buildWelcomeState();

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
              _buildMessageInput(isPremium),
            ],
          ),
        );
      }
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 15),
          Text("ai_no_messages".tr(), style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 3,
        itemBuilder: (context, index) {
          final List<String> suggestions = [
            "ai_sugg_budget".tr(),
            "ai_sugg_coffee".tr(),
            "ai_sugg_nearby".tr(),
          ];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ActionChip(
              label: Text(suggestions[index], style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
              onPressed: () => _sendMessage(suggestions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? dropRed : (isDark ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 20),
          ),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 16)),
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

  Widget _buildMessageInput(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, 
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1)))
      ),
      child: Row(
        children: [
          Tooltip(
            message: "visual_search_tooltip".tr(),
            child: IconButton(
              icon: Icon(Icons.camera_alt_rounded, color: isPremium ? dropRed : Colors.grey),
              onPressed: () => _pickAndAnalyzeImage(isPremium),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.withOpacity(0.1))
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: "ai_input_hint".tr(), 
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                ),
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
