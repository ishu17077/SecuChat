import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding_router.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageStorage extends StatefulWidget {
  final AuthViewModel _authViewModel;
  final IDataSource _dataSource;
  ManageStorage(
      {required AuthViewModel authViewModel,
      required IDataSource dataSource,
      super.key})
      : _authViewModel = authViewModel,
        _dataSource = dataSource;

  @override
  State<ManageStorage> createState() => _ManageStorageState();
}

class _ManageStorageState extends State<ManageStorage> {
  bool _keyRegenerated = false;
  bool _isRegenerateButtonLoading = false;
  bool _clearAllChatsButtonLoading = false;
  bool _chatsCleared = false;
  bool _exportChatsLoading = false;
  bool _chatsExported = false;

  @override
  void initState() {
    // TODO: implement initState
    print("In Manage Storage Screen");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/sign_in_logo.png',
                height: 250,
                width: 300,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.12),
                child: const Text("Login",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Stack(
              children: [
                button(
                  context,
                  text: "Regenerate Private Key",
                  textColor: Colors.black,
                  spaceBetween: 10.0,
                  color: const Color.fromARGB(220, 255, 255, 255),
                  imagePath: 'assets/private_key.png',
                  heightImage: 38.0,
                  widthImage: 38.0,
                  onPressed: () async => await _regenerateEncryptionKeys(),
                ),
                _isRegenerateButtonLoading
                    ? const Center(
                        heightFactor: 1.4, child: CircularProgressIndicator())
                    : const SizedBox(height: 0.0, width: 0.0)
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Stack(
              children: [
                button(
                  context,
                  text: "Export Chats",
                  textColor: Colors.black,
                  spaceBetween: 10.0,
                  color: const Color.fromARGB(220, 255, 255, 255),
                  imagePath: 'assets/export_chats.png',
                  heightImage: 38.0,
                  widthImage: 38.0,
                  onPressed: () async => await _exportChats(),
                ),
                _clearAllChatsButtonLoading
                    ? const Center(
                        heightFactor: 1.4, child: CircularProgressIndicator())
                    : const SizedBox(height: 0.0, width: 0.0)
              ],
            ),
            // Stack(
            //   children: [
            //     signInButton(
            //       context,
            //       text: "Continue with Facebook",
            //       spaceBetween: 5.0,
            //       color: const Color.fromARGB(220, 24, 119, 242),
            //       textColor: Colors.white,
            //       imagePath: 'assets/facebook_icon.png',
            //       heightImage: 32.0,
            //       widthImage: 32.0,
            //       onPressed: () {
            //         if (!isLoadingWithGoogle && !isLoadingWithFacebook) {
            //           setState(() {
            //             isLoadingWithFacebook = true;
            //           });
            //           FirebaseAuth.instance.signOut();
            //           setState(() {
            //             isLoadingWithFacebook = false;
            //           });
            //         }
            //       },
            //     ),
            //     isLoadingWithFacebook
            //         ? const Center(
            //             heightFactor: 1.4, child: CircularProgressIndicator())
            //         : const SizedBox(height: 0.0, width: 0.0)
            //   ],
            // ),
            //TODO: Impl Email and password auth
            // SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            // Stack(
            //   children: [
            //     signInButton(
            //       context,
            //       text: "Continue with Mail ;)",
            //       color: const Color.fromARGB(255, 70, 62, 88),
            //       textColor: Colors.white38,
            //       imagePath: 'assets/email_icon.png',
            //       heightImage: 31.7,
            //       widthImage: 31.7,
            //       onPressed: () {
            //         if (!isLoadingWithGoogle && !isLoadingWithFacebook) {
            //           Navigator.of(context).push(MaterialPageRoute(
            //             builder: (context) => EmailAndPasswordAuthentication(),
            //           ));
            //         }
            //       },
            //     ),
            //   ],
            // ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    EdgeInsets.all(MediaQuery.of(context).size.height * 0.017),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  child: const Text(
                    "Need help with something?",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'devsrayash@gmail.com',
                      queryParameters: {
                        "subject": "Error",
                        'body': '',
                      },
                    );
                    if (await canLaunchUrl(emailLaunchUri)) {
                      launchUrl(emailLaunchUri);
                    }
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget button(BuildContext context,
      {String? text,
      Color? color,
      Color? textColor,
      String? imagePath,
      double? spaceBetween,
      double? heightImage,
      double? widthImage,
      VoidCallback? onPressed}) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: color,
          minimumSize: Size(MediaQuery.of(context).size.width * 0.8,
              MediaQuery.of(context).size.height * 0.05),
          maximumSize: Size(MediaQuery.of(context).size.width * 0.80,
              MediaQuery.of(context).size.height * 0.055),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            imagePath != null
                ? Image.asset(imagePath,
                    height: heightImage ?? 38.0, width: widthImage ?? 38.0)
                : const SizedBox(),
            SizedBox(width: spaceBetween ?? 5.0),
            Align(
              alignment: Alignment.center,
              child: Text(
                text ?? 'How about continuing with some brain ;D',
                style: TextStyle(
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateEncryptionKeys() async {
    if (_isRegenerateButtonLoading ||
        _clearAllChatsButtonLoading ||
        _exportChatsLoading) return;
    if (_keyRegenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Keys have been already regenerated!!")));
      return;
    }
    _isRegenerateButtonLoading = true;
    try {
      final user = await widget._authViewModel.regenerateEncryption();
      _keyRegenerated = true;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Error updating the keys, check your internet connection and try again!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Key generation successful!!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Error updating the keys, check your internet connection and try again!")));
    } finally {
      _isRegenerateButtonLoading = false;
    }
  }

  Future<void> _exportChats() async {
    if (_isRegenerateButtonLoading ||
        _clearAllChatsButtonLoading ||
        _exportChatsLoading) return;
    _exportChatsLoading = true;
    try {
      // if (!(await _requestStoragePermission())) {
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //       content: Text("Allow storage permission to export the database!")));
      //   return;
      // }
      final dbPath = widget._dataSource.getDatabasePath();
      final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: "Please select output file to save database",
          fileName: "secuchatDb.db",
          bytes: await File(dbPath).readAsBytes(),
          type: FileType.custom);
      if (outputPath == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Unable to save database!")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("File saved!")));
      }
    } catch (e) {
      print("An error occurred while saving the file: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Unable to save database!")));
    } finally {
      _exportChatsLoading = false;
    }
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status == PermissionStatus.denied) {
      await Permission.storage.request();
      status = await Permission.storage.status; // Re-check status after request
    }
    return status.isGranted;
  }
}
