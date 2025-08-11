import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ChatScreen extends StatefulWidget {
  final String departmentName;

  const ChatScreen({super.key, required this.departmentName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> messages = [];
  bool isLoading = false;
  String extractedPdfText = ''; // Store extracted PDF text
  String currentPdfName = ''; // Store current PDF name
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
final String serpApiKey = dotenv.env['SERP_API_KEY'] ?? '';
final String newsApiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  @override
  void initState() {
    super.initState();
    messages.add({
      'role': 'assistant',
      'text':
          'Welcome to Shasanmitra! I am here to assist with your queries for the ${widget.departmentName} department. Type a question or upload a PDF to get started.',
      'timestamp': DateTime.now().toIso8601String(),
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _controller.addListener(() => setState(() {}));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Extract text from PDF using Syncfusion
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      // Load the PDF document
      final PdfDocument document = PdfDocument(inputBytes: File(filePath).readAsBytesSync());
      
      // Create a PDF text extractor
      PdfTextExtractor extractor = PdfTextExtractor(document);
      
      // Extract text from all pages
      String extractedText = extractor.extractText();
      
      // Dispose the document
      document.dispose();
      
      return extractedText.trim();
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return '';
    }
  }

  // Check if query needs real-time information
  bool _needsRealTimeInfo(String query) {
    final realtimeKeywords = [
      'today', 'now', 'current', 'latest', 'recent', 'this week', 'this month', 
      'breaking', 'news', 'weather', 'stock', 'price', 'rate', 'update',
      'happening', 'trending', 'live', '2024', '2025', 'yesterday', 'tomorrow',
      'what time', 'date', 'when', 'status', 'ongoing', 'active'
    ];
    
    return realtimeKeywords.any((keyword) => 
      query.toLowerCase().contains(keyword));
  }

  // Get current information using multiple sources
  Future<String> getCurrentInfo(String query) async {
    String results = '';
    
    // Try SerpAPI first (Google Search)
    try {
      final serpResponse = await http.get(
        Uri.parse('https://serpapi.com/search.json?engine=google&q=${Uri.encodeComponent(query)}&api_key=$serpApiKey&num=3'),
      );

      if (serpResponse.statusCode == 200) {
        final data = jsonDecode(serpResponse.body);
        final organicResults = data['organic_results'] as List?;
        
        if (organicResults != null && organicResults.isNotEmpty) {
          results += "📊 Current Search Results:\n\n";
          
          for (int i = 0; i < organicResults.length && i < 3; i++) {
            final result = organicResults[i];
            results += "${i + 1}. ${result['title']}\n";
            results += "${result['snippet']}\n";
            results += "Source: ${result['link']}\n\n";
          }
        }
      }
    } catch (e) {
      print('SerpAPI error: $e');
    }

    // If search query contains "news", try NewsAPI
    if (query.toLowerCase().contains('news') || query.toLowerCase().contains('breaking')) {
      try {
        final newsResponse = await http.get(
          Uri.parse('https://newsapi.org/v2/top-headlines?country=in&apiKey=$newsApiKey&pageSize=3'),
        );

        if (newsResponse.statusCode == 200) {
          final newsData = jsonDecode(newsResponse.body);
          final articles = newsData['articles'] as List?;
          
          if (articles != null && articles.isNotEmpty) {
            results += "\n📰 Latest News Headlines:\n\n";
            
            for (int i = 0; i < articles.length && i < 3; i++) {
              final article = articles[i];
              results += "${i + 1}. ${article['title']}\n";
              results += "${article['description'] ?? 'No description available'}\n";
              results += "Published: ${article['publishedAt']}\n";
              results += "Source: ${article['url']}\n\n";
            }
          }
        }
      } catch (e) {
        print('NewsAPI error: $e');
      }
    }

    return results;
  }

  // Perform web search for real-time information (kept for backward compatibility)
  Future<String> performWebSearch(String query) async {
    return await getCurrentInfo(query);
  }

  Future<void> sendMessage({String? customPrompt}) async {
    final userMessage = customPrompt ?? _controller.text.trim();
    if (userMessage.isEmpty) return;

    String finalMessage = userMessage;
    if (finalMessage.toLowerCase().contains('who are you')) {
      finalMessage =
          'Please respond with: "I am Shasanmitra, developed by the Shasanmitra team or Tejas Barguje."';
    }

    setState(() {
      messages.add({
        'role': 'user',
        'text': finalMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _controller.clear();
      isLoading = true;
    });

    // Check if we need real-time information
    String searchResults = '';
    if (_needsRealTimeInfo(finalMessage)) {
      searchResults = await performWebSearch(finalMessage);
    }

    // Build chat history (excluding system messages for API)
    final chatHistory = messages.where((msg) => msg['role'] != 'system').map((msg) {
      return {"role": msg['role'], "content": msg['text']};
    }).toList();

    // Prepare system prompt with current date and search results
    String systemPrompt = "You are Shasanmitra, a professional assistant for the '${widget.departmentName}' department. Today's date is ${DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now())}. Always provide current, up-to-date information when possible. Maintain conversation history.";
    
    // Add search results if available
    if (searchResults.isNotEmpty) {
      systemPrompt += "\n\nREAL-TIME SEARCH RESULTS:\n$searchResults\nUse this current information to answer the user's query accurately.";
    }
    
    // If we have extracted PDF text, include it in the system prompt
    if (extractedPdfText.isNotEmpty) {
      systemPrompt += "\n\nIMPORTANT: A PDF document named '$currentPdfName' has been uploaded with the following content:\n\n$extractedPdfText\n\nWhen answering questions, prioritize information from this PDF document. If the user asks questions related to the content of this PDF, base your answers on the extracted text above. Always mention when you're referencing information from the uploaded PDF.";
    }

    try {
      print('Sending message with system prompt length: ${systemPrompt.length}'); // Debug log
      print('PDF text available: ${extractedPdfText.isNotEmpty ? "Yes (${extractedPdfText.length} chars)" : "No"}'); // Debug log
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content": systemPrompt
            },
            ...chatHistory,
          ],
          "max_tokens": 1500,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];

        setState(() {
          messages.add({
            'role': 'assistant',
            'text': reply,
            'timestamp': DateTime.now().toIso8601String(),
          });
          isLoading = false;
        });
      } else {
        print('OpenAI API error: ${response.statusCode} - ${response.body}'); // Debug log
        setState(() {
          messages.add({
            'role': 'assistant',
            'text': 'Error: Unable to fetch response. Please try again. (Error ${response.statusCode})',
            'timestamp': DateTime.now().toIso8601String(),
          });
          isLoading = false;
        });
      }
    } catch (e) {
      print('Send message error: $e'); // Debug log
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': 'Error: Network issue. Please check your connection and try again.',
          'timestamp': DateTime.now().toIso8601String(),
        });
        isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _focusNode.requestFocus();
    });
  }

  Future<void> pickAndSummarizePDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      messages.add({
        'role': 'user',
        'text': '[Uploading PDF: ${result.files.single.name}...]',
        'timestamp': DateTime.now().toIso8601String(),
      });
      isLoading = true;
    });

    try {
      // Extract text from PDF
      final String extractedText = await extractTextFromPdf(result.files.single.path!);
      
      if (extractedText.isEmpty) {
        setState(() {
          messages.add({
            'role': 'assistant',
            'text': 'Error: Could not extract text from the PDF. The file might be image-based or corrupted.',
            'timestamp': DateTime.now().toIso8601String(),
          });
          isLoading = false;
        });
        return;
      }

      // Store the extracted text and PDF name for future queries
      extractedPdfText = extractedText;
      currentPdfName = result.files.single.name;

      print('PDF text extracted successfully. Length: ${extractedText.length} characters'); // Debug log

      // Create system prompt with PDF content
      String systemPrompt = """You are Shasanmitra, a helpful assistant for the ${widget.departmentName} department. 
      
A PDF document named '${result.files.single.name}' has been successfully uploaded and processed.

EXTRACTED PDF CONTENT:
$extractedText

Please analyze this PDF content and provide a comprehensive summary including:
1. Main topic/subject of the document
2. Key points and important information
3. Any data, statistics, or specific details mentioned
4. Overall purpose of the document

Then inform the user that they can now ask specific questions about any content from this PDF.""";

      // Get AI summary of the PDF
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content": systemPrompt
            },
            {
              "role": "user",
              "content": "Please analyze and summarize the uploaded PDF document.",
            }
          ],
          "max_tokens": 1500,
          "temperature": 0.3
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];

        setState(() {
          messages.add({
            'role': 'assistant',
            'text': '✅ PDF Successfully Processed: ${result.files.single.name}\n\n$reply',
            'timestamp': DateTime.now().toIso8601String(),
          });
          isLoading = false;
        });
      } else {
        setState(() {
          messages.add({
            'role': 'assistant',
            'text': '✅ PDF uploaded and text extracted successfully: ${result.files.single.name}\n\n📄 Document contains ${extractedText.split(' ').length} words and ${extractedText.split('\n').length} lines.\n\nYou can now ask me specific questions about the content of this PDF document.',
            'timestamp': DateTime.now().toIso8601String(),
          });
          isLoading = false;
        });
      }
    } catch (e) {
      print('PDF processing error: $e'); // Debug log
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': 'Error: Failed to process PDF. Please ensure the file is a valid PDF and try again. Error: $e',
          'timestamp': DateTime.now().toIso8601String(),
        });
        isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _focusNode.requestFocus();
    });
  }

  Widget buildMessageBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    final timestamp = msg['timestamp'] ?? '';
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: msg['text']!));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Message copied to clipboard',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                ),
                backgroundColor: Colors.deepPurple.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? Colors.deepPurple.shade600 : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg['text']!,
                  style: GoogleFonts.roboto(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                if (timestamp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('hh:mm a').format(DateTime.parse(timestamp)),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: isUser ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Bounce(
                infinite: true,
                duration: const Duration(milliseconds: 500),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Bounce(
                infinite: true,
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 100),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Bounce(
                infinite: true,
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 200),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey.shade100,
        textTheme: GoogleFonts.robotoTextTheme(),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          accentColor: Colors.purpleAccent,
          backgroundColor: Colors.grey.shade100,
        ).copyWith(surface: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              ElasticIn(
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.departmentName[0],
                    style: GoogleFonts.roboto(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shasanmitra - ${widget.departmentName}',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    if (currentPdfName.isNotEmpty)
                      Text(
                        '📄 $currentPdfName loaded',
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          elevation: 0,
          actions: [
            if (currentPdfName.isNotEmpty)
              ZoomIn(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Remove PDF',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      extractedPdfText = '';
                      currentPdfName = '';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PDF removed from context',
                          style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                        ),
                        backgroundColor: Colors.deepPurple.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ZoomIn(
              child: IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.white),
                tooltip: 'Clear Chat',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    messages.clear();
                    messages.add({
                      'role': 'assistant',
                      'text':
                          'Conversation reset. Ask anything about ${widget.departmentName}.',
                      'timestamp': DateTime.now().toIso8601String(),
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Conversation cleared',
                        style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                      ),
                      backgroundColor: Colors.deepPurple.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _buildTypingIndicator();
                  }
                  return buildMessageBubble(messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ZoomIn(
                    child: IconButton(
                      icon: Icon(
                        Icons.upload_file, 
                        color: currentPdfName.isNotEmpty 
                          ? Colors.green.shade600 
                          : Colors.deepPurple.shade600
                      ),
                      tooltip: currentPdfName.isNotEmpty 
                        ? 'PDF loaded: $currentPdfName' 
                        : 'Upload PDF',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        pickAndSummarizePDF();
                      },
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: currentPdfName.isNotEmpty 
                          ? 'Ask about the uploaded PDF...' 
                          : 'Ask a question or type a command...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.deepPurple.shade300),
                        ),
                      ),
                      style: GoogleFonts.roboto(fontSize: 16),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          HapticFeedback.lightImpact();
                          sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ZoomIn(
                    child: CircleAvatar(
                      backgroundColor: _controller.text.trim().isEmpty
                          ? Colors.grey.shade400
                          : Colors.deepPurple.shade600,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                sendMessage();
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}














// Note: Ensure you have the necessary packages in your pubspec.yaml:
// file_picker, http, intl, animate_do, google_fonts, syncfusion_flutter_pdf, syncfusion_flutter_pdfviewer