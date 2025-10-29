import 'dart:async';
import 'package:chat/chat.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/message/message_bloc.dart';
import 'package:secuchat/state_management/message_thread/message_thread_cubit.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/ui/pages/chatPage/message_thread/components/chat_pill.dart';
import 'package:secuchat/ui/pages/chatPage/message_thread/components/chat_text_field.dart';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

class MessageThread extends StatefulWidget {
  final User receiver;
  final User me;
  final String chatId;
  final MessageBloc messageBloc;
  final TypingNotifBloc typingNotifBloc;
  final ChatsCubit chatsCubit;
  const MessageThread(this.receiver, this.me, this.messageBloc, this.chatsCubit,
      this.typingNotifBloc,
      {super.key, this.chatId = ''});
  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread>
    with WidgetsBindingObserver {
  late User? signedInUser;
  final TextEditingController _textEditingController = TextEditingController();
  double heightOfTextField = 0;
  int count = 0;
  final GlobalKey _textBoxChangeKey = GlobalKey();
  Timer? _startTypingTimer;
  Timer? _stopTypingTimer;
  late List<LocalMessage> messages = [];
  late String chatId = widget.chatId;
  late User receiver = widget.receiver;
  late final StreamSubscription subscription;
  bool initialScrollDone = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    context.read<ReceiptBloc>().add(ReceiptEvent.onSubscribed(widget.me));

    receiver.id != null
        ? context.read<TypingNotifBloc>().add(TypingNotifEvent.subscribed(
            widget.me,
            userWithChats: [receiver.id!]))
        : null;
    _updateOnMessageReceived();
    _updateOnReceiptReceived();
    //! _mystream was seperately assigned as it was changing with everytime something happens like a keyboard pop up lol, and that was bad like horrible, we need bloc
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // sticky?.remove();
    // stickeyKey.currentState?.dispose();
    subscription.cancel();
    _startTypingTimer?.cancel();
    _stopTypingTimer?.cancel();
    _textEditingController
        .removeListener(() => _textEditingController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (chatId.isNotEmpty) {
          await context
              .read<MessageThreadCubit>()
              .messages(chatId, forceRefresh: true);
        }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0.0,
        scrolledUnderElevation: 0.0,

        forceMaterialTransparency: true,
        leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              opticalSize: 15,
              size: 15,
              color: Colors.white70,
            ),
            onPressed: () {
              Navigator.pop(context);
            }),
        backgroundColor: kBackgroundColor,
        // elevation: 10,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Hero(
              tag: chatId.isEmpty ? '_' : chatId,
              child: CircleAvatar(
                backgroundColor: kSexyTealColor,
                backgroundImage: NetworkImage(widget.receiver.photoUrl ??
                    'https://www.shutterstock.com/image-photo/red-text-any-questions-paper-600nw-2312396111.jpg'),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Text(
              widget.receiver.name ??
                  '', //? Jab change karne ka option hoga username tab server se refresh karenge
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0.0, bottom: 15.0),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child:
                  BlocBuilder<MessageThreadCubit, List<LocalMessage>>(
                      builder: (context, messages) {
                this.messages = messages;
                if (messages.isEmpty) return SizedBox();
                return _buildListOfMessages();
              })),
              Align(
                alignment: Alignment.bottomCenter,
                child: ChatTextField(
                  key: _textBoxChangeKey,
                  textEditingController: _textEditingController,
                  onChanged: _sendTypingNotification,
                  onSendButtonPressed: (String contents) async {
                    _sendMessage();
                  },
                ),
              ),
            ],
          ),
        ),

        // }),
      ),
    );
  }

  Widget _buildListOfMessages() => ListView.builder(
        reverse: true,
        itemBuilder: (context, index) {
          // bool noMarginRequired = messageStore.senderEmail ==
          //     (previousMessageStore?.senderEmail ??
          //         ''); //? for some weird reason when previousMessageStore is null it actually returns true
          final message = messages[index];
          var isMe = _isMe(message.message.from, widget.me.id!);
          if (!isMe && message.receipt.status != ReceiptStatus.read) {
            _sendReceipt(message);
          }
          return ChatPill(
            text: message.message.contents,
            receiptStatus: message.receipt.status,
            isLastMessage:
                index == 0, //? Listview is reverse so 0 index = last at screen
            isMe: isMe,
            noMaginRequired: index != 0
                ? message.message.from == messages[index - 1].message.from
                : true,
          );
        },
        itemCount: messages.length,
      );

  void _sendMessage() async {
    final text = _textEditingController.text.trim();
    if (text.isNotEmpty) {
      final iv = IV.fromSecureRandom(16);
      final Message message = Message(
          from: widget.me.id!,
          to: widget.receiver.id!,
          contents: text,
          time: DateTime.now(),
          iv: iv);

      widget.messageBloc.add(MessageEvent.onMessageSent(message));

      _textEditingController.clear();
      _startTypingTimer?.cancel();
    }
  }

  void _sendReceipt(LocalMessage message) async {
    if (message.receipt.status == ReceiptStatus.read) return;
    final receipt = Receipt(
      messageId: message.message.id!,
      recipientId: message.message.to,
      status: ReceiptStatus.read,
      time: DateTime.now(),
    );
    context.read<ReceiptBloc>().add(ReceiptEvent.onMessageSent(receipt));
    await context
        .read<MessageThreadCubit>()
        .chatViewModel
        .updateMessageReceipt(receipt);
  }

  void _sendTypingNotification(String text) {
    if (text.trim().isEmpty || messages.isEmpty) {
      return;
    }
    if (_startTypingTimer?.isActive ?? false) return;
    if (_stopTypingTimer?.isActive ?? false) _stopTypingTimer!.cancel();

    _dispatchTypingEvent(Typing.start);
    _startTypingTimer = Timer(Duration(seconds: 3), () {});

    _stopTypingTimer =
        Timer(Duration(seconds: 4), () => _dispatchTypingEvent(Typing.stop));
  }

  void _dispatchTypingEvent(Typing typing) {
    final TypingEvent typingEvent = TypingEvent(
        from: widget.me.id!, to: widget.receiver.id!, event: typing);
    widget.typingNotifBloc.add(TypingNotifEvent.sent(typingEvent));
  }

  bool _isMe(String sender, String myId) {
    bool isMe = sender == myId ? true : false;
    return isMe;
  }

  void _updateOnReceiptReceived() async {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    final receiptBloc = context.read<ReceiptBloc>();
    if (chatId.isNotEmpty) {
      messageThreadCubit.messages(chatId);
    }

    subscription = widget.messageBloc.stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        await messageThreadCubit.chatViewModel.recieveMessage(state.message);
        final receipt = Receipt(
            messageId: state.message.id!,
            recipientId: state.message.from,
            status: ReceiptStatus.read,
            time: DateTime.now());

        receiptBloc.add(ReceiptEvent.onMessageSent(receipt));
      }
      if (state is MessageSentSuccess) {
        await messageThreadCubit.chatViewModel.sentMessage(state.message);
        if (chatId.isEmpty) {
          chatId = messageThreadCubit.chatViewModel.chatId ??
              messageThreadCubit.chatViewModel.chats
                  .firstWhere((chat) => chat.userId == state.message.to)
                  .id;
        }
      }

      await messageThreadCubit.messages(chatId);
      await widget.chatsCubit.chats();
    });
  }

  void _updateOnMessageReceived() {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    context.read<ReceiptBloc>().stream.listen((state) async {
      if (state is ReceiptReceivedSuccess) {
        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(state.receipt);
        messageThreadCubit.messages(chatId);
        widget.chatsCubit.chats();
      }
    });
  }

//TODO: Impl Async Encryption
  // Uint8List _iv() {
  //   var random = Random.secure();
  //   List<int> ivList = List<int>.generate(8, (_) => random.nextInt(99));
  //   Uint8List iv = Uint8List.fromList(ivList);
  //   return iv;
  // }
  //! isSeen not working
}
