import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int? orderId;
  final String? customerName;
  const ChatScreen({super.key, this.orderId, this.customerName});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final s = RestaurantChatService();
  final c = TextEditingController();
  bool loading = true, sending = false;
  String? error;

  @override void initState() { super.initState(); _connect(); }
  Future<void> _connect() async {
    try { await s.connect(orderId: widget.orderId); if (mounted) setState(() => loading = false); }
    catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); }
  }
  Future<void> _send() async {
    final text = c.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try { await s.send(text); c.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override void dispose() { c.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final title = '${widget.customerName ?? 'Customer'}${widget.orderId != null ? ' • Order #${widget.orderId}' : ''}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: s.messages(),
                        builder: (context, snap) {
                          if (snap.hasError) return Center(child: Text('${snap.error}'));
                          final ms = snap.data ?? <Map<String, dynamic>>[];
                          return ListView.builder(
                            reverse: true,
                            itemCount: ms.length,
                            itemBuilder: (context, i) {
                              final m = ms[ms.length - 1 - i];
                              final mine = m['sender']?.toString() == 'staff';
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                                  decoration: BoxDecoration(
                                    color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text('${m['message'] ?? ''}', style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Row(
                        children: [
                          Expanded(child: TextField(controller: c, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Type a reply...', contentPadding: EdgeInsets.symmetric(horizontal: 16)))),
                          IconButton(onPressed: _send, icon: sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
