import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secuchat/databases/chat_database_helper.dart';
import 'package:secuchat/databases/message_database_helper.dart';
import 'package:secuchat/encryption/encryption.dart';
import 'package:secuchat/encryption/encryption_methods.dart';
import 'package:secuchat/models/chat_store.dart';
import 'package:secuchat/models/message.dart' as serverMessage;
import 'package:secuchat/models/user.dart';
import 'package:secuchat/notifications/local_notification_service.dart';
import 'package:secuchat/saving_data/saving_and_retrieving_non_trivial_data.dart';
import 'package:secuchat/server_functions/add_new_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('In firebaseMessagingBackgroundHandler');
  await Firebase.initializeApp();
  int _id = Random().nextInt(9999998) + 1111111;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String privateKeyJwk = (await futurePrivateKeyJwk)!;
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  _localNotificationService.showNotificationChecker(
      title: 'SecuChat', body: 'Securing your world for you.....', id: 9999999);
  QuerySnapshot documentSnapshot = await _firestore
      .collection('messages')
      .where('recipient_email', isEqualTo: AddNewUser.signedInUser!.email!)
      .orderBy('time', descending: true)
      .get();
  String messageNotif = "";
  for (QueryDocumentSnapshot queryDocumentSnapshot in documentSnapshot.docs) {
    var data = queryDocumentSnapshot.data()!;
    bool doesChatExist = false;
    final serverMessage.Message message =
        serverMessage.Message.fromJson(data as Map<String, dynamic>);
    print(message.senderEmail);
    String publicKeyJwk =
        await SavingAndRetrievingNonTrivialData.retrievePublicKeyForUserEmail(
                prefs,
                email_address: message.senderEmail) ??
            (await _firestore
                .collection('users')
                .where('email_address', isEqualTo: message.recipientEmail)
                .get()
                .then((snapshot) {
              User user = User.fromJson(snapshot.docs.first.data());
              return user.publicKeyJwb!;
            }));
    message.id = queryDocumentSnapshot.id;

    var deriveKey2 = await deriveKey(privateKeyJwk, publicKeyJwk);
    decryptedMessage(
      iv: message.iv,
      encryptedMessageContents: message.contents,
      deriveKey: deriveKey2,
    ).then((decryptedMessageContents) {
      _chatDatabaseHelper.getChatsList().then((value) {
        for (var element in value) {
          if (element.belongsToEmail == message.senderEmail) {
            doesChatExist = true;
            break;
          }
        }

        ChatStore chatStore = ChatStore(
            //! name parameter missing
            belongsToEmail: message.senderEmail,
            photoUrl:
                'https://www.shutterstock.com/image-photo/red-text-any-questions-paper-600nw-2312396111.jpg',
            userIdFromServer: 'wdddwd',
            mostRecentMessage: null);

        if (!doesChatExist) {
          _chatDatabaseHelper.getChatsList().then((value) {
            for (var element in value) {
              if (element.belongsToEmail == message.senderEmail) {
                doesChatExist = true;
                chatStore.name = element.name;
                chatStore.photoUrl = element.photoUrl;
                chatStore.belongsToEmail = element.belongsToEmail;
                chatStore.userIdFromServer = element.userIdFromServer;
                break;
              }
            }
          });
          if (!doesChatExist) {
            _firestore
                .collection('users')
                .where('email_address', isEqualTo: message.senderEmail)
                .get()
                .then((value) async {
              final User newUserFromWhomWeGotMessage = User.fromJson(
                  value.docs.first.data()! as Map<String, dynamic>);
              chatStore.name = newUserFromWhomWeGotMessage.username!;
              chatStore.photoUrl = newUserFromWhomWeGotMessage.photoUrl!;
              chatStore.userIdFromServer = newUserFromWhomWeGotMessage.id!;
              chatStore.belongsToEmail =
                  newUserFromWhomWeGotMessage.emailAddress;
              // chatStore.mostRecentMessage = messageStore;
              await _chatDatabaseHelper.insertChat(chatStore);
              messageNotif = "$decryptedMessageContents\n$messageNotif";
              SavingAndRetrievingNonTrivialData.retrieveEmailNotifId(
                      prefs: prefs, email_address: message.senderEmail)
                  .then((notifId) {
                if (notifId != null) {
                  _localNotificationService.showNotificationMessage(
                      id: notifId,
                      title: chatStore.name ?? 'Anonymous',
                      body: messageNotif ?? '');
                } else {
                  _localNotificationService.showNotificationMessage(
                      id: _id,
                      title: chatStore.name ?? 'Anonymous',
                      body: messageNotif ?? '');

                  SavingAndRetrievingNonTrivialData.saveEmailsAsNotifId(
                      prefs: prefs,
                      id: _id,
                      email_address: message.senderEmail);
                }
              });
            });
          } else {
            //? Double chatExists checks because an instance occured where my chat was registered twice

            // chatStore.mostRecentMessage = messageStore;
            messageNotif = "$decryptedMessageContents\n$messageNotif";
            SavingAndRetrievingNonTrivialData.retrieveEmailNotifId(
                    prefs: prefs, email_address: message.senderEmail)
                .then((notifId) {
              if (notifId != null) {
                _localNotificationService.showNotificationMessage(
                    id: notifId,
                    title: chatStore.name ?? 'Anonymous',
                    body: messageNotif ?? '');
              } else {
                _localNotificationService.showNotificationMessage(
                    id: _id,
                    title: chatStore.name ?? 'Anonymous',
                    body: messageNotif ?? '');

                SavingAndRetrievingNonTrivialData.saveEmailsAsNotifId(
                    prefs: prefs, id: _id, email_address: message.senderEmail);
              }
            });
          }
        } else {
          // chatStore.mostRecentMessage = messageStore;

          messageNotif = "$decryptedMessageContents\n$messageNotif";
          SavingAndRetrievingNonTrivialData.retrieveEmailNotifId(
                  prefs: prefs, email_address: message.senderEmail)
              .then((notifId) {
            if (notifId != null) {
              _localNotificationService.showNotificationMessage(
                  id: notifId,
                  title: chatStore.name ?? 'Anonymouse',
                  body: messageNotif ?? '');
            } else {
              _localNotificationService.showNotificationMessage(
                  id: _id,
                  title: chatStore.name ?? 'Anonymouse',
                  body: messageNotif ?? '');

              SavingAndRetrievingNonTrivialData.saveEmailsAsNotifId(
                  prefs: prefs, id: _id, email_address: message.senderEmail);
            }
          });
        }
      });
    });
  }
  _localNotificationService.dismissNotification(9999999);

  // debugPrint("Handling a background message: ${message.messageId}");
  // debugPrint("Title: ${message.notification?.title}");
  // debugPrint("Body: ${message.notification?.body}");
  // debugPrint("Payload: ${message.data}");
  // return;
}

// final MessageDatabaseHelper _messageDatabaseHelper = MessageDatabaseHelper();
Map<String, List<String?>> mapMessages = {};
Map<String?, int> mapMessageIdToEmail = {};
final ChatDatabaseHelper _chatDatabaseHelper = ChatDatabaseHelper();
final LocalNotificationService _localNotificationService =
    LocalNotificationService();
Future<String?> futurePrivateKeyJwk = EncryptionMethods.getPrivateKeyJwk();

Future<void> onMessageRecieved(RemoteMessage message) async {
  print('Hi');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  Future<void> initNotifications() async {
    await _firebaseMessaging.subscribeToTopic(AddNewUser.signedInUser!.email!
        .replaceAll('@', '_')); //? Subscribing to listen to just my email
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);
    // GetMessages().setData(fCMTokenRegisteredName, fCMToken!);
    // _messageDatabaseHelper.initializeDatabase();
    _chatDatabaseHelper.initializeDatabase();
    _localNotificationService.initialize();
    FirebaseMessaging.onMessage.listen(onMessageRecieved);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
