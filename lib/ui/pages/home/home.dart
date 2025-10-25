// ignore_for_file: use_build_context_synchronously
import 'dart:isolate';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/home/home_cubit.dart';
import 'package:secuchat/state_management/message/message_bloc.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/ui/pages/home/home_router.dart';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class Home extends StatefulWidget {
  final User me;
  final IHomeRouter router;
  final EncryptionViewmodel encryption;
  const Home(this.me, this.router, this.encryption, {super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Chat> chats = [];
  List<String> typingEvents = [];
  int count = 0;
  bool keepLoading = true;
  bool shouldHideTextField = false;
  late User _user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _user = widget.me;
    _initialSetup();
  }

  void _initialSetup() async {
    final user =
        (!_user.active) ? await context.read<HomeCubit>().connect() : _user;
    await context.read<ChatsCubit>().chats();
    context.read<HomeCubit>().activeUsers(widget.me);
    //! Spawn isolates
    await widget.encryption.preCacheKeys();
    //! me should be user from above comment
    context.read<MessageBloc>().add(MessageEvent.subscribed(widget.me));
    _updateChatsOnMessageReceived();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        print('AppCycleState resumed');
        // _chatStream?.resume();
        // _chatStream?.resume();
        // _chatStream?.resume();
        // _chatStream?.resume();
        // _chatStream?.resume();
        // _chatStream?.resume();
        // updateListView();

        break;
      case AppLifecycleState.inactive:
        print('AppCycleState inactive');

        break;
      case AppLifecycleState.paused:
        print('AppCycleState paused');
        // _chatStream?.pause();
        break;
      case AppLifecycleState.detached:
        print('AppCycleState detached');
        // _chatStream?.pause();
        break;
      case AppLifecycleState.hidden:
        print('AppCycleState hidden');
        // _chatStream?.pause();
        // _chatStream?.pause();
        break;
    }
  }

  @override
  void dispose() {
    // _chatStream?.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // _chatStream?.resume();
    // updateListView();

    super.didChangeDependencies();
  }

  // List<Message> messages = [];
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          //TODO: Impl do not build app bar and searchbar as it is costly
          child:
              BlocConsumer<ChatsCubit, List<Chat>>(listener: (context, chats) {
            context.read<TypingNotifBloc>().add(TypingNotifEvent.subscribed(
                  widget.me,
                  userWithChats: chats
                      .map((chat) => chat.from.id)
                      .whereType<
                          String>() //? Returns itearable of type string not string? which removes null
                      .toList(),
                ));
          }, builder: (context, chats) {
            this.chats = chats;
            return _buildHome();
          }),
        ));
  }

  Widget _buildHome() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: SizedBox(height: 10)),
        _buildSearchBar(),
        SliverToBoxAdapter(child: SizedBox(height: 5)),
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => chatTile(chats[index], context),
                childCount: chats.length))
      ],
      // body: Column(
      //   mainAxisSize: MainAxisSize.max,
      //   children: [
      //     _buildSearchBar(),
      //     SizedBox(height: 5),
      //     _buildListView(),
      //   ],
      // ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      elevation: 0.0,
      leading: null,
      collapsedHeight: 60,
      backgroundColor: kBackgroundColor,
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 0,
              left: 8.0,
              right: 11.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Conversations",
                  style: TextStyle(
                    fontSize: 35,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                MaterialButton(
                  padding:
                      EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                  color: kSexyTealColor.withValues(alpha: 0.8),
                  elevation: 5,
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                    gapPadding: 2.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: kBackgroundColor,
                      ),
                      Text(
                        "Add New",
                        style: TextStyle(color: kBackgroundColor, fontSize: 13),
                      ),
                    ],
                  ),
                  onPressed: () => widget.router
                      .onShowNewChatUi(context, widget.me, widget.encryption),
                ),
              ],
            ),
          ))
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 10.0),
        child: TextField(
          showCursor: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            fillColor: kTextFieldColor,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.teal),
            labelStyle: TextStyle(color: Colors.white),
          ),
          cursorColor: Colors.teal,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget chatTile(Chat chat, BuildContext context) {
    return ListTile(
      tileColor: kBackgroundColor,
      splashColor: kSexyTealColor.withValues(alpha: 0.2),
      leading: Hero(
        tag: chat.id,
        child: CircleAvatar(
          backgroundImage: NetworkImage(chat.from?.photoUrl ??
              'https://www.shutterstock.com/image-photo/red-text-any-questions-paper-600nw-2312396111.jpg'),
        ),
      ),
      title: Text(
        chat.from?.name ?? '',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: BlocBuilder<TypingNotifBloc, TypingNotifState>(
        builder: (_, state) {
          //TODO: This implementaion doesn't need to be so big work on this
          if (state is TypingReceivedSuccess &&
              state.typingEvent.event == Typing.start &&
              state.typingEvent.from == chat.from?.id) {
            this.typingEvents.add(state.typingEvent.from);
          } else if (state is TypingReceivedSuccess &&
              state.typingEvent.event == Typing.stop &&
              state.typingEvent.from == chat.from?.id) {
            this.typingEvents.remove(state.typingEvent.from);
          }
          if (this.typingEvents.contains(chat.from?.id)) {
            return Text(
              "typing...",
              style:
                  TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
            );
          }

          return Text(
            chat.mostRecent?.message.contents ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          );
        },
      ),
      onTap: () async {
        await this.widget.router.onShowMessageThread(
            context, chat.from, widget.me, widget.encryption,
            chatId: chat.id);
      },
      enabled: true,
      enableFeedback: true,
    );
  }

  void _updateChatsOnMessageReceived() async {
    final chatsCubit = context.read<ChatsCubit>();
    context.read<MessageBloc>().stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        await chatsCubit.viewModel
            .receivedMessage(state.message.from, state.message)
            .then(
              (_) async => await chatsCubit.chats(),
            );
      }
    });
  }
}
