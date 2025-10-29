import 'package:bloc/bloc.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/viewmodels/chats/chats_view_model.dart';

class ChatsCubit extends Cubit<List<Chat>> {
  final ChatsViewModel viewModel;
  ChatsCubit(this.viewModel) : super([]);
  Future<void> chats({bool forceRefresh = false}) async {
    if (forceRefresh) viewModel.forceRefresh();
    final chats = await viewModel.getChats();
    emit([...chats]);
  }
}
