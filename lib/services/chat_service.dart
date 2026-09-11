import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class RestaurantChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _threadId;

  Future<void> connect({int? orderId}) async {
    final url = orderId == null ? ApiConfig.chatFirebaseToken : ApiConfig.chatFirebaseToken(orderId);
    final res = await ApiClient.get(url);
    _threadId = res['thread_id']?.toString();
    final token = res['token']?.toString();
    if (token == null || token.isEmpty) throw Exception('Chat authentication failed.');
    await FirebaseAuth.instance.signInWithCustomToken(token);
  }

  Stream<List<QueryDocumentSnapshot<Map<String,dynamic>>>> inbox(int restaurantId) => _db.collection('chat_threads').where('restaurantId', isEqualTo: restaurantId).snapshots().map((s) => s.docs.where((d) => d.data()['recipientRole'] == 'manager').toList());

  Stream<List<Map<String,dynamic>>> messages() {
    if (_threadId == null) return const Stream.empty();
    return _db.collection('chat_threads').doc(_threadId).collection('messages').orderBy('createdAt').snapshots().map((s) => s.docs.map((d)=>d.data()).toList());
  }

  String? get threadId => _threadId;

  Future<void> send(String text) async {
    if (_threadId == null) throw Exception('Chat is not connected.');
    final ref=_db.collection('chat_threads').doc(_threadId);
    await ref.update({'lastMessage':text,'lastMessageAt':FieldValue.serverTimestamp(),'unreadForCustomer':FieldValue.increment(1),'unreadForStaff':0});
    await ref.collection('messages').add({'sender':'staff','message':text,'type':'text','createdAt':FieldValue.serverTimestamp()});
  }
}
