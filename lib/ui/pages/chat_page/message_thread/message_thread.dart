import 'dart:async';
import 'package:chat/chat.dart';
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
import 'package:secuchat/viewmodels/chats/base_view_model.dart';

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
  final TextEditingController _textEditingController = TextEditingController();
  double heightOfTextField = 0;
  late final messageThreadCubit = context.read<MessageThreadCubit>();
  late final messageBloc = context.read<MessageBloc>();
  late final typingNotifBloc = context.read<TypingNotifBloc>();
  late final MessageThreadCubit _messageThreadCubit;
  int count = 0;
  final GlobalKey _textBoxChangeKey = GlobalKey();
  Timer? _startTypingTimer;
  Timer? _stopTypingTimer;

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
    _updateInitialReceipts();
    _updateOnMessageReceived();
    _updateOnReceiptReceived();

    //! _mystream was seperately assigned as it was changing with everytime something happens like a keyboard pop up lol, and that was bad like horrible, we need bloc
    super.initState();
  }

  void _updateInitialReceipts() async {
    final messages = await messageThreadCubit.chatViewModel.getMessages(chatId);
    count = 0;
    for (var message in messages) {
      if (message.receipt.status == ReceiptStatus.sending) {
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
        if (chatId.isNotEmpty && mounted) {
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
        break;
      case AppLifecycleState.detached:
        print('AppCycleState detached');
        break;
      case AppLifecycleState.hidden:
        print('AppCycleState hidden');
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
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBackButton(
              onPressed: () => navigatorKey.currentState?.pop(),
            ),
            BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                if (state is MessageReceivedSuccess &&
                    state.message.from != receiver.id) {
                  return _messageThreadCubit.chatViewModel.otherMessages != 0
                      ? CircleAvatar(
                          backgroundColor: Colors.red,
                          maxRadius: 4,
                        )
                      : SizedBox();
                }
                return SizedBox();
              },
            ),
          ],
        ),
        backgroundColor: kBackgroundColor,
        // elevation: 10,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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

              return Flexible(
                child: ChatHeader(
                  username: widget.receiver.name ?? '',
                  isTyping: isTyping,
                ),
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
                if (messages.isEmpty) return SizedBox();
                return _buildListOfMessages(messages);
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

  Widget _buildListOfMessages(List<LocalMessage> messages) => ListView.builder(
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
    if (text.length > 2000) {
      _textEditingController.clear();
      return;
    }
    if (text.isNotEmpty) {
      final Message message = Message(
        from: widget.me.id!,
        to: widget.receiver.id!,
        contents: text,
        time: DateTime.now(),
      );
      final receipt = Receipt(
        messageId: "",
        recipientId: message.from,
        status: ReceiptStatus.read,
        time: DateTime.now(),
      );
      try {
        if (chatId.isEmpty) {
          widget.chatsCubit.chats(forceRefresh: true);
        }
        chatId = chatId.isEmpty
            ? messageThreadCubit.chatViewModel.chatId ??
                messageThreadCubit.chatViewModel.chats
                    .firstWhere((chat) => chat.userId == message.to)
                    .id
            : chatId;
      } catch (e) {
        debugPrint("chatid not found");
      }
      String id = await messageThreadCubit.chatViewModel
          .sentMessage(message, status: ReceiptStatus.sending);
      var localMessage =
          LocalMessage(message, receipt, userId: widget.receiver.id!);
      localMessage.receipt = receipt;
      localMessage.chatId = chatId;
      localMessage = BaseViewModel.mapIdToLocalMessage(localMessage, id);
      localMessage.chatId = chatId;
      if (id.isNotEmpty) {
        messageBloc.add(MessageEvent.onMessageSent(localMessage));
      }
      _textEditingController.clear();
      _startTypingTimer?.cancel();
    }
  }

  Future<void> _sendReceipt(Message message, Receipt receipt) async {
    if (receipt.status == ReceiptStatus.read) return;
    receipt = Receipt(
      messageId: message.id!,
      recipientId: message.from,
      status: ReceiptStatus.read,
      time: DateTime.now(),
    );
    context.read<ReceiptBloc>().add(ReceiptEvent.onMessageSent(receipt));
    await messageThreadCubit.chatViewModel.updateMessageReceipt(receipt);
  }

  void _sendTypingNotification(String text) {
    if (text.trim().isEmpty || chatId.isEmpty) {
      return;
    }
    if (_startTypingTimer?.isActive ?? false) return;
    if (_stopTypingTimer?.isActive ?? false) _stopTypingTimer!.cancel();
    _dispatchTypingEvent(Typing.start);
    _startTypingTimer = Timer(Duration(seconds: 4), () {});
    _stopTypingTimer =
        Timer(Duration(seconds: 3), () => _dispatchTypingEvent(Typing.stop));
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
        if (state.message.from != widget.receiver.id) {
          messageThreadCubit.chatViewModel.otherMessages++;
          return;
        }
        await messageThreadCubit.chatViewModel.recieveMessage(state.message);
        final receipt = Receipt(
            messageId: state.message.id!,
            recipientId: state.message.from,
            status: ReceiptStatus.delivered,
            time: DateTime.now());
        _sendReceipt(state.message, receipt);
        messageThreadCubit.messages(chatId);
        widget.chatsCubit.chats();
      } else if (state is MessageSentSuccess) {
        final receipt = Receipt(
            messageId: state.message.message.id!,
            recipientId: state.message.message.from,
            status: ReceiptStatus.sent,
            time: DateTime.now());
        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(receipt,
                localMessageId: state.message.id,
                sMessage: state.message.message)
            .then((_) {
          messageThreadCubit.messages(chatId);
          widget.chatsCubit.chats();
        });
      } else if (state is MessageSentFailed) {
      } else if (state is MessageResendSuccess) {
        final receipt = Receipt(
            messageId: state.message.message.id!,
            recipientId: state.message.message.from,
            status: ReceiptStatus.sent,
            time: DateTime.now());
        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(receipt,
                localMessageId: state.message.id,
                sMessage: state.message.message)
            .then(
          (_) {
            messageThreadCubit.messages(chatId);
            widget.chatsCubit.chats();
          },
        );
      } else if (state is MessageSending) {
        messageThreadCubit.messages(chatId);
        widget.chatsCubit.chats();
      }
    });
  }

  void _updateOnReceiptReceived() {
    final messageThreadCubit = context.read<MessageThreadCubit>();
    context.read<ReceiptBloc>().stream.listen((state) async {
      if (state is ReceiptReceivedSuccess) {
        await messageThreadCubit.chatViewModel
            .updateMessageReceipt(state.receipt)
            .then((_) {
          messageThreadCubit.messages(chatId);
          widget.chatsCubit.chats();
        });
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
