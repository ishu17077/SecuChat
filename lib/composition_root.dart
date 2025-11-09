import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/data/datasources/sqflite_datasource_impl.dart';
import 'package:secuchat/data/factories/db_factory_impl.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/notifications/awesome_notification_impl.dart';
import 'package:secuchat/notifications/firebase_api.dart';
import 'package:secuchat/notifications/notification_service_contract.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/home/home_cubit.dart';
import 'package:secuchat/state_management/message/message_bloc.dart';
import 'package:secuchat/state_management/message_thread/message_thread_cubit.dart';
import 'package:secuchat/state_management/onboarding/onboarding_cubit.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/ui/pages/chat_page/new_chat/new_chat.dart';
import 'package:secuchat/ui/pages/chat_page/message_thread/message_thread.dart';
import 'package:secuchat/ui/pages/home/home.dart';
import 'package:secuchat/ui/pages/home/home_router.dart';
import 'package:secuchat/ui/pages/miscellaneous/manage_storage.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding_router.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';
import 'package:secuchat/viewmodels/auth/email_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/auth/google_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';
import 'package:secuchat/viewmodels/chats/chat_view_model.dart';
import 'package:secuchat/viewmodels/chats/chats_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart' hide Key;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class CompositionRoot {
  static late FirebaseFirestore _firebaseFirestore;
  static late FirebaseDatabase _firebaseDatabase;
  static late FirebaseAuth _firebaseAuth;
  static late GoogleSignIn _googleSignIn;
  static late IUserService _userService;
  static late Database _db;
  static late AwesomeNotifications _awesomeNotifications;
  static late IMessageService _messageService;
  static late ITypingNotification _typingNotification;
  static late IReceiptService _receiptService;
  static late IDataSource _dataSource;
  static late ILocalCache _localCache;
  static late IEncryption _encryption;
  static late MessageBloc _messageBloc;
  static late ReceiptBloc _receiptBloc;
  static late TypingNotifBloc _typingNotifBloc;
  static late ChatsCubit _chatsCubit;
  static late HomeCubit _homeCubit;
  static late AuthViewModel _authViewModel;
  static late GoogleSignInViewModel _googleSignInViewModel;
  static late EmailSignInViewModel _emailSignInViewModel;
  static late INotificationService notificationService;
  static late FirebaseMessaging _firebaseMessaging;
  static late BaseViewModel _baseViewModel;
  static late HomeRouter _homeRouter;
  static User? _user;
  static late EncryptionViewmodel _encryptionViewmodel;
  static late FirebaseNotifications _firebaseNotifications;

  static Future<void> configure() async {
    await Firebase.initializeApp();
    _firebaseFirestore = FirebaseFirestore.instance;
    _firebaseDatabase = FirebaseDatabase.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn.instance;
    _userService = UserService(_firebaseFirestore);
    _db = await LocalDatabaseFactory().getDatabase();
    _encryption = EncryptionService();
    _messageService = MessageService(_firebaseFirestore);
    _typingNotification = TypingNotification(_firebaseDatabase);
    _receiptService = ReceiptService(_firebaseFirestore);
    _firebaseMessaging = FirebaseMessaging.instance;
    _dataSource = SqfliteDatasource(_db);
    final encryptedSharedPref = EncryptedSharedPreferences(
        prefs: await SharedPreferences.getInstance(),
        mode: AESMode.gcm,
        randomKeyKey: 'Color#E2330');
    _localCache = LocalCache(encryptedSharedPref);
    _encryptionViewmodel = EncryptionViewmodel(
        _encryption, _dataSource, _localCache, _userService);
    _messageBloc = MessageBloc(_messageService, _encryptionViewmodel);
    _typingNotifBloc = TypingNotifBloc(_typingNotification);
    _receiptBloc = ReceiptBloc(_receiptService);
    _baseViewModel = BaseViewModel(_dataSource, _userService);
    final viewModel =
        ChatsViewModel(_baseViewModel, encryption: _encryptionViewmodel);
    _chatsCubit = ChatsCubit(viewModel);
    _homeCubit = HomeCubit(_userService, _localCache);

    _authViewModel = AuthViewModel(
        _firebaseAuth, _userService, _localCache, _encryptionViewmodel);
    _googleSignInViewModel = GoogleSignInViewModel(_googleSignIn, _firebaseAuth,
        _userService, _localCache, _encryptionViewmodel);
    _emailSignInViewModel = EmailSignInViewModel(
        _firebaseAuth, _userService, _localCache, _encryptionViewmodel);
    _awesomeNotifications = AwesomeNotifications();
    notificationService = AwesomeNotificationService(
      _awesomeNotifications,
      _messageService,
      _dataSource,
      _encryptionViewmodel,
      _localCache,
    );

    _homeRouter = HomeRouter(composeMessageThreadUi, composeNewChatUi);
    var status = await Permission.notification.status;

    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  static Widget start() {
    final String initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    // print("Initial Route name $initialRoute");
    // if (initialRoute == "/manage-storage") {
    //   return composeManageStorageUi();
    // }
    _user = _authViewModel.signedInUser;

    return _handleNavigation(_user);
  }

  static Widget composeHomeUi(User me) {
    _startNotificationService(me);
    removeAllNotifications();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _chatsCubit),
        BlocProvider(create: (context) => _messageBloc),
        BlocProvider(create: (context) => _typingNotifBloc),
        BlocProvider(create: (context) => _receiptBloc),
        BlocProvider(create: (context) => _homeCubit),
      ],
      child: Home(me, _homeRouter, _encryptionViewmodel),
    );
  }

  static void removeAllNotifications() {
    notificationService.cancelAll();
  }

  static Widget composeMessageThreadUi(
      User receiver, User me, EncryptionViewmodel encryption,
      {String? chatId}) {
    if (chatId != null) {
      notificationService.removeChatNotification(chatId);
    }
    final viewModel = ChatViewModel(_baseViewModel, chatId: chatId);
    final messageThreadCubit = MessageThreadCubit(viewModel);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => messageThreadCubit),
        BlocProvider.value(value: _receiptBloc),
        BlocProvider.value(value: _typingNotifBloc),
        BlocProvider.value(value: _messageBloc),
      ],
      child: MessageThread(receiver, me, _chatsCubit, chatId: chatId ?? ''),
    );
  }

  static Widget composeOnboardingUi() {
    _googleSignIn.initialize();
    OnboardingCubit onboardingCubit = OnboardingCubit(
        _authViewModel, _emailSignInViewModel, _googleSignInViewModel);
    final IOnboardingRouter onboardingRouter = OnboardingRouter(composeHomeUi);
    return MultiBlocProvider(providers: [
      BlocProvider(create: (context) => onboardingCubit),
      //TODO: Image Cubit
    ], child: Onboarding(onboardingRouter));
  }

  static Widget composeNewChatUi(User me, EncryptionViewmodel encryption) {
    return MultiBlocProvider(providers: [
      BlocProvider.value(value: _chatsCubit),
      BlocProvider.value(value: _homeCubit)
    ], child: NewChat(me, _homeRouter, encryption));
  }

  static void _startNotificationService(User me) async {
    _firebaseNotifications = FirebaseNotifications(_firebaseMessaging, me);
    await _firebaseNotifications.initNotifications();
    // await _notificationService.createTempNotif(999);
  }

  static Widget _handleNavigation(User? user) {
    if (user != null) {
      handleNotificationEvents();
      // _awesomeNotifications.setListeners(onActionReceivedMethod: _checkPayload);
    }
    return user != null ? composeHomeUi(user) : composeOnboardingUi();
  }

  static void handleNotificationEvents() async {
    final Future<ReceivedAction?> receivedAction =
        _awesomeNotifications.getInitialNotificationAction();
    receivedAction.then(_checkPayload);
  }

  static Future<void> _checkPayload(ReceivedAction? receivedAction) async {
    if (receivedAction != null &&
        receivedAction.payload != null &&
        receivedAction.payload!["chat_id"] != null &&
        receivedAction.payload!["user.id"] != null) {
      final user =
          await _dataSource.findUser(receivedAction.payload!["user.id"]!);
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (context) => composeMessageThreadUi(
              user!, _user!, _encryptionViewmodel,
              chatId: user.id)));
    }
  }

  static Future<void> createNotification(
      Chat chat, LocalMessage message) async {
    await notificationService.createNotification(chat, message);
  }

  static Widget composeManageStorageUi() {
    return ManageStorage(
        authViewModel: _authViewModel, dataSource: _dataSource);
  }

  // static Widget composeNotifications() {
  //   final INotificationService notificationService =
  //       AwesomeNotificationService(AwesomeNotifications());

  //   //!Test

  //   final Message message = Message(
  //     from: "2edwd",
  //     to: "dasdsd",
  //     contents: "Hey Baby!",
  //     time: DateTime.now(),
  //   );
  //   final Map<String, dynamic> receiptMap = {
  //     "message_id": "dwdwd",
  //     "recipient_id": '2ewd',
  //     "id": "sdsdsdwdwdwd",
  //     "status": "sent",
  //     "time": Timestamp.now(),
  //   };
  //   LocalMessage localMessage =
  //       LocalMessage(message, Receipt.fromJSON(receiptMap), userId: '1');
  //   localMessage.chatId = '1';
  //   Chat chat = Chat('1');
  //   chat.from = User(
  //       name: 'wdld',
  //       email: 'sddwsd',
  //       username: 'username',
  //       lastSeen: DateTime.now(),
  //       publicKeyJwb: 'sdsddd');

  //   chat.messages = [localMessage];
  //   chat.mostRecent = localMessage;

  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     body: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         ElevatedButton(
  //             onPressed: () async {
  //               await notificationService.initialize();
  //               await notificationService.createNotification(
  //                   chat, localMessage);
  //             },
  //             child: Text("Show notif"))
  //       ],
  //     ),
  //   );
  // }
}
