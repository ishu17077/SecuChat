import 'package:bloc/bloc.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/viewmodels/chats/chat_view_model.dart';

class MessageThreadCubit extends Cubit<List<LocalMessage>> {
  final ChatViewModel chatViewModel;
  MessageThreadCubit(this.chatViewModel) : super([]);

  Future<void> messages(String chatId, {bool forceRefresh = false}) async {
    if (forceRefresh) chatViewModel.forceRefresh(chatId);
    final messages = await chatViewModel.getMessages(chatId);
    if (isClosed) return;
    emit([...messages]);
  }
}
