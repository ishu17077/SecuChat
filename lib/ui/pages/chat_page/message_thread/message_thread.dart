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
import 'package:secuchat/ui/pages/chat_page/message_thread/components/chat_header.dart';
import 'package:secuchat/ui/pages/chat_page/message_thread/components/chat_pill.dart';
import 'package:secuchat/ui/pages/chat_page/message_thread/components/chat_text_field.dart';
import 'package:secuchat/ui/widgets/app_back_button.dart';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

class MessageThread extends StatefulWidget {
  final User receiver;
  final User me;
  final String chatId;
  final ChatsCubit chatsCubit;

  const MessageThread(this.receiver, this.me, this.chatsCubit,
      {super.key, this.chatId = ''});
  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread>
    with WidgetsBindingObserver {
  late User? signedInUser;
  final TextEditingController _textEditingController = TextEditingController();
  double heightOfTextField = 0;

  late final messageBloc = context.read<MessageBloc>();
  // late final chatsCubit = widget.chatsCubit;
  late final typingNotifBloc = context.read<TypingNotifBloc>();
  late final MessageThreadCubit _messageThreadCubit;
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
    _messageThreadCubit = context.read<MessageThreadCubit>();
    context.read<ReceiptBloc>().add(ReceiptEvent.onSubscribed(widget.me));

    receiver.id != null
        ? context.read<TypingNotifBloc>().add(TypingNotifEvent.subscribed(
            widget.me,
            userWithChats: [receiver.id!]))
        : null;
    _updateOnMessageReceived();
    _updateOnReceiptReceived();
    _updateInitialReceipts();
    //! _mystream was seperately assigned as it was changing with everytime something happens like a keyboard pop up lol, and that was bad like horrible, we need bloc
    super.initState();
  }

  void _updateInitialReceipts() async {
    final messages = await context
        .read<MessageThreadCubit>()
        .chatViewModel
        .getMessages(chatId);
    count = 0;
    for (var message in messages) {
      if (message.receipt.status == ReceiptStatus.sending) {
        message.message.iv = IV.fromSecureRandom(16);
        messageBloc.add(MessageEvent.onMessageResend(message));
      }
      var isMe = _isMe(message.message.from, widget.me.id!);
      if (!isMe && message.receipt.status != ReceiptStatus.read) {
        _sendReceipt(message.message, message.receipt);
      }
      if (!isMe && count++ == 25) return;
    }
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
          context
              .read<MessageThreadCubit>()
              .messages(chatId, forceRefresh: true)
              .then(
            (value) {
              _updateInitialReceipts();
            },
          );
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
        leading: Stack(
          children: [
            //_messageThreadCubit.chatViewModel.otherMessages != 0
            //     ? CircleAvatar(
            //         backgroundColor: Colors.red,
            //         child: Text(
            //           "${context.read<MessageThreadCubit>().chatViewModel.otherMessages}",
            //           textScaler: TextScaler.linear(0.5),
            //         ),
            //       )
            //     : SizedBox(),
            AppBackButton(
              onPressed: () => navigatorKey.currentState?.pop(),
            ),
          ],
        ),
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
            BlocBuilder<TypingNotifBloc, TypingNotifState>(
                builder: (context, state) {
              final isTyping = state is TypingReceivedSuccess &&
                  state.typingEvent.event == Typing.start &&
                  state.typingEvent.from == widget.receiver.id;

              return ChatHeader(
                username: widget.receiver.name ?? '',
                isTyping: isTyping,
              );
            }),
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
                  // onChanged: _sendTypingNotification,
                  onChanged: (changed) {},
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

      messageBloc.add(MessageEvent.onMessageSent(message));

      _textEditingController.clear();
      _startTypingTimer?.cancel();
    }
  }

  void _sendReceipt(Message message, Receipt receipt) async {
    if (receipt.status == ReceiptStatus.read) return;
    receipt = Receipt(
      messageId: message.id!,
      recipientId: message.to,
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
    _startTypingTimer = Timer(Duration(seconds: 8), () {});

    _stopTypingTimer =
        Timer(Duration(seconds: 7), () => _dispatchTypingEvent(Typing.stop));
  }

  void _dispatchTypingEvent(Typing typing) {
    final TypingEvent typingEvent = TypingEvent(
        from: widget.me.id!,
        to: widget.receiver.id!,
        event: typing,
        time: DateTime.now());
    typingNotifBloc.add(TypingNotifEvent.sent(typingEvent));
  }

  bool _isMe(String sender, String myId) {
    bool isMe = sender == myId ? true : false;
    return isMe;
  }

  void _updateOnMessageReceived() async {
    final messageThreadCubit = _messageThreadCubit;
    if (chatId.isNotEmpty) {
      messageThreadCubit.messages(chatId);
    }

    subscription = messageBloc.stream.listen((state) async {
      if (state is MessageReceivedSuccess) {
        await messageThreadCubit.chatViewModel.recieveMessage(state.message);
        final receipt = Receipt(
            messageId: state.message.id!,
            recipientId: state.message.from,
            status: ReceiptStatus.delivered,
            time: DateTime.now());

        _sendReceipt(state.message, receipt);
      } else if (state is MessageSentSuccess) {
        await messageThreadCubit.chatViewModel.sentMessage(state.message);
        if (chatId.isEmpty) {
          chatId = chatId.isEmpty
              ? messageThreadCubit.chatViewModel.chatId ??
                  messageThreadCubit.chatViewModel.chats
                      .firstWhere((chat) => chat.userId == state.message.to)
                      .id
              : chatId;
        }
      } else if (state is MessageSentFailed) {
        chatId = chatId.isEmpty
            ? messageThreadCubit.chatViewModel.chatId ??
                messageThreadCubit.chatViewModel.chats
                    .firstWhere((chat) => chat.userId == state.message.to)
                    .id
            : chatId;
        await messageThreadCubit.chatViewModel
            .sentMessage(state.message, status: ReceiptStatus.sending);
      } else if (state is MessageResendSuccess) {
        final receipt = Receipt(
            messageId: state.message.message.id!,
            recipientId: state.message.message.from,
            status: ReceiptStatus.sent,
            time: DateTime.now());

        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(receipt, localMessageId: state.message.id);
      }

      await messageThreadCubit.messages(chatId);
      await widget.chatsCubit.chats();
    });
  }

  void _updateOnReceiptReceived() {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    context.read<ReceiptBloc>().stream.listen((state) async {
      if (state is ReceiptReceivedSuccess) {
        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(state.receipt);
        messageThreadCubit.messages(chatId);
        widget.chatsCubit.chats();
      }
    } );
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
