import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/home/home_cubit.dart';
import 'package:secuchat/state_management/home/home_state.dart';
import 'package:secuchat/ui/pages/home/home_router.dart';
import 'package:secuchat/ui/widgets/app_back_button.dart';
import 'package:secuchat/ui/widgets/dev_container.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class NewChat extends StatefulWidget {
  final User me;
  final IHomeRouter homeRouter;
  final EncryptionViewmodel encryption;
  const NewChat(this.me, this.homeRouter, this.encryption, {super.key});

  @override
  State<NewChat> createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {
  late final ChatsCubit chatsCubit;

  @override
  void initState() {
    chatsCubit = context.read<ChatsCubit>();
    context.read<HomeCubit>().activeUsers(widget.me);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          leading: AppBackButton(onPressed: () => Navigator.pop(context)),
          elevation: 0,
          title: const Text(
            "People you can talk to",
            style: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: kBackgroundColor,
        body: BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
          if (state is HomeLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is HomeSuccess) {
            return ListView(
                children: state.onlineUsers.map((user) {
              return chatTile(user);
            }).toList());
          }
          return Center(child: Text("Error!! Please try again :o"));
        }));
  }

  Widget chatTile(User user) {
    return ListTile(
      tileColor: kBackgroundColor,
      splashColor: kSexyTealColor.withValues(alpha: 0.2),
      leading: CircleAvatar(
        backgroundColor: kSexyTealColor,
        backgroundImage: NetworkImage(user.photoUrl ??
            'https://marmelab.com/images/blog/ascii-art-converter/homer.png'),
      ),
      trailing:
          user.id == "1oSLDBOyjANs6BsBURTV52aM5s33" ? DevContainer() : null,
      title: Text(
        user.name ?? '',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        user.username ?? '**No Username**',
        style: const TextStyle(color: Colors.white70),
      ),
      onTap: () => widget.homeRouter.onShowMessageThread(
          context, user, widget.me, widget.encryption,
          chatId: _chatChatExists(user.id!)),
      enabled: true,
      enableFeedback: true,
    );
  }

  String? _chatChatExists(String userId) {
    var chats = chatsCubit.viewModel.chats;
    for (Chat chat in chats) {
      if (chat.userId == userId) {
        return chat.id;
      }
    }

    return null;
  }
}
