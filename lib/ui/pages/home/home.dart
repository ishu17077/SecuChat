// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:isolate';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:secuchat/composition_root.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/home/home_cubit.dart';
import 'package:secuchat/state_management/message/message_bloc.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/ui/pages/home/home_router.dart';
import 'package:secuchat/ui/widgets/app_search_bar.dart';
import 'package:secuchat/ui/widgets/chat_tile.dart';
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
  String _searchQuery = "";
  List<String> typingEvents = [];
  int count = 0;
  bool keepLoading = true;
  late final StreamSubscription _messageSubscription;
  bool shouldHideTextField = false;
  late User _user;
  late final _messageBloc = context.read<MessageBloc>();

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
    context.read<MessageBloc>().resume();
    _updateChatsOnMessageReceived();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        print('AppCycleState resumed');
        context.read<MessageBloc>().resume();
        context.read<TypingNotifBloc>().resume();
        _messageSubscription.resume();
        context.read<ReceiptBloc>().resume();
        CompositionRoot.handleNotificationEvents();
        await context.read<ChatsCubit>().chats(forceRefresh: true);
        CompositionRoot.removeAllNotifications();
        break;
      case AppLifecycleState.inactive:
        print('AppCycleState inactive');

        break;
      case AppLifecycleState.paused:
        context.read<MessageBloc>().pause();
        context.read<TypingNotifBloc>().pause();
        _messageSubscription.resume();
        context.read<ReceiptBloc>().pause();
        print('AppCycleState paused');
        // _chatStream?.pause();
        break;
      case AppLifecycleState.detached:
        // context.read<MessageBloc>().pause();
        print('AppCycleState detached');
        // _chatStream?.pause();
        break;
      case AppLifecycleState.hidden:
        // context.read<MessageBloc>().pause();
        print('AppCycleState hidden');
        // _chatStream?.pause();
        // _chatStream?.pause();
        break;
    }
  }

  @override
  void dispose() {
    // _chatStream?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription.cancel();
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
            final List<Chat> filteredChats;
            filteredChats = _searchChats(chats);
            return _buildHome(filteredChats);
          }),
        ));
  }

  List<Chat> _searchChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) {
      return chats;
    } else {
      final filteredChats = chats.where((chat) {
        // 3. Use your filter logic (now fixed and lowercase)
        if (chat.from.name.toLowerCase().contains(_searchQuery)) {
          return true;
        }
        if (chat.from.username.toLowerCase().contains(_searchQuery)) {
          return true;
        }
        if (chat.mostRecent != null &&
            chat.mostRecent!.message.contents
                .toLowerCase()
                .contains(_searchQuery)) {
          return true;
        }
        return false;
      }).toList();
      return filteredChats;
    }
  }

  Widget _buildHome(List<Chat> chats) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: SizedBox(height: 10)),
        _buildSearchBar(),
        SliverToBoxAdapter(child: SizedBox(height: 5)),
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => ChatTile(chats[index], onTap: () async {
                      setState(() {
                        chats[index].unread = 0;
                      });
                      await widget.router.onShowMessageThread(context,
                          chats[index].from, widget.me, widget.encryption,
                          chatId: chats[index].id);
                    }, unread: chats[index].unread),
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
        child: AppSearchBar(
            title: "Search",
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            }),
      ),
    );
  }

  void _updateChatsOnMessageReceived() async {
    final chatsCubit = context.read<ChatsCubit>();
    final receiptBloc = context.read<ReceiptBloc>();
    _messageSubscription = _messageBloc.stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        receiptBloc.add(ReceiptEvent.onMessageSent(Receipt(
            messageId: state.message.id!,
            recipientId: state.message.from,
            status: ReceiptStatus.delivered,
            time: DateTime.now())));
        (await chatsCubit.viewModel
            .receivedMessage(state.message.from, state.message));

        await chatsCubit.chats();
      }
    });
  }
}
