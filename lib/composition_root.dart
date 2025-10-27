import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/data/datasources/sqflite_datasource_impl.dart';
import 'package:secuchat/data/factories/db_factory_impl.dart';
import 'package:secuchat/state_management/home/chats_cubit.dart';
import 'package:secuchat/state_management/home/home_cubit.dart';
import 'package:secuchat/state_management/message/message_bloc.dart';
import 'package:secuchat/state_management/message_thread/message_thread_cubit.dart';
import 'package:secuchat/state_management/onboarding/onboarding_cubit.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/ui/pages/chatPage/add_new_chat/new_chat.dart';
import 'package:secuchat/ui/pages/chatPage/message_thread/message_thread.dart';
import 'package:secuchat/ui/pages/home/home.dart';
import 'package:secuchat/ui/pages/home/home_router.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding_router.dart';
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';
import 'package:secuchat/viewmodels/auth/email_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/auth/google_sign_in_view_model.dart';
import 'package:secuchat/viewmodels/chats/chat_view_model.dart';
import 'package:secuchat/viewmodels/chats/chats_view_model.dart';
import 'package:encrypt/encrypt.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart' hide Key;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class CompositionRoot {
  static late FirebaseFirestore _firebaseFirestore;
  static late FirebaseAuth _firebaseAuth;
  static late GoogleSignIn _googleSignIn;
  static late IUserService _userService;
  static late Database _db;
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
  static late HomeRouter _homeRouter;
  static late EncryptionViewmodel _encryptionViewmodel;

  static Future<void> configure() async {
    await Firebase.initializeApp();
    _firebaseFirestore = FirebaseFirestore.instance;
    _firebaseAuth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn.instance;
    _userService = UserService(_firebaseFirestore);
    _db = await LocalDatabaseFactory().getDatabase();
    _encryption = EncryptionService();
    _messageService = MessageService(_firebaseFirestore);
    _typingNotification = TypingNotification(_firebaseFirestore);
    _receiptService = ReceiptService(_firebaseFirestore);
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
    final viewModel = ChatsViewModel(_dataSource,
        userService: _userService, encryption: _encryptionViewmodel);
    _chatsCubit = ChatsCubit(viewModel);
    _homeCubit = HomeCubit(_userService, _localCache);

    _authViewModel = AuthViewModel(
        _firebaseAuth, _userService, _localCache, _encryptionViewmodel);
    _googleSignInViewModel = GoogleSignInViewModel(_googleSignIn, _firebaseAuth,
        _userService, _localCache, _encryptionViewmodel);
    _emailSignInViewModel = EmailSignInViewModel(
        _firebaseAuth, _userService, _localCache, _encryptionViewmodel);

    _homeRouter = HomeRouter(composeMessageThreadUi, composeNewChatUi);
  }

  static Widget start() {
    final user = _authViewModel.signedInUser;
    return user != null ? composeHomeUi(user) : composeOnboardingUi();
  }

  static Widget composeHomeUi(User me) {
    //TODO: Final Impl
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

  static Widget composeMessageThreadUi(
      User receiver, User me, EncryptionViewmodel encryption,
      {String? chatId}) {
    final viewModel = ChatViewModel(_dataSource, _userService);
    final messageThreadCubit = MessageThreadCubit(viewModel);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => messageThreadCubit),
        BlocProvider.value(value: _receiptBloc),
        BlocProvider.value(value: _typingNotifBloc),
      ],
      child: MessageThread(
          receiver, me, _messageBloc, _chatsCubit, _typingNotifBloc,
          chatId: chatId ?? ''),
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

  static void composeNotifications(User me){
    
  }
}
