import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget { const ChatsScreen({super.key}); @override State<ChatsScreen> createState()=>_ChatsScreenState(); }
class _ChatsScreenState extends State<ChatsScreen> {
  final service=RestaurantChatService(); bool loading=true; String? error;
  @override void initState(){super.initState(); _connect();}
  Future<void> _connect() async { try { await service.connect(); if(mounted)setState(()=>loading=false); } catch(e){if(mounted)setState(()=>{loading=false,error=e.toString()});} }
  @override Widget build(BuildContext context){
    final manager=context.watch<AppState>().currentManager;
    final restaurantId=_restaurantId(manager);
    return Scaffold(appBar: AppBar(title: const Text('Customer Chats')),body: loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):restaurantId==null?const Center(child:Text('Restaurant information unavailable.')):StreamBuilder<List<QueryDocumentSnapshot<Map<String,dynamic>>>>(stream:service.inbox(restaurantId),builder:(c,s){
      if(s.hasError)return Center(child:Text('${s.error}')); final docs=s.data??[]; if(docs.isEmpty)return const Center(child:Text('No customer chats yet.'));
      docs.sort((a,b){final at=a.data()['lastMessageAt'];final bt=b.data()['lastMessageAt'];final aa=at is Timestamp?at.millisecondsSinceEpoch:0;final bb=bt is Timestamp?bt.millisecondsSinceEpoch:0;return bb.compareTo(aa);});
      return ListView.separated(itemCount:docs.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(c,i){final d=docs[i].data();final oid=(d['orderId'] as num?)?.toInt();return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text((d['customerName']??'Customer').toString()),subtitle:Text('${oid!=null?'Order #$oid • ':''}${(d['lastMessage']??'').toString()}',maxLines:1,overflow:TextOverflow.ellipsis),trailing:(d['unreadForStaff'] as num?)?.toInt()==0?null:CircleAvatar(radius:10,child:Text('${(d['unreadForStaff'] as num?)?.toInt()}',style:const TextStyle(fontSize:10))),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(orderId:oid,customerName:d['customerName']?.toString()))));});
    }));
  }
  int? _restaurantId(dynamic manager){try{return manager?.restaurantId as int?;}catch(_){return null;}}
}
