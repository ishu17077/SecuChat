import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/ui/helpers/suffix_icon.dart';
import 'package:secuchat/ui/widgets/beautiful_button.dart';
import 'package:secuchat/ui/widgets/my_form_field.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/auth/auth_view_model.dart';
import 'package:secuchat/viewmodels/miscellaneous/miscellaneous_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageStorage extends StatelessWidget {
  final AuthViewModel _authViewModel;
  final IDataSource _dataSource;

  ManageStorage(
      {required AuthViewModel authViewModel,
      required IDataSource dataSource,
      super.key})
      : _authViewModel = authViewModel,
        _dataSource = dataSource;

  bool _keyRegenerated = false;
  bool _isRegenerateButtonLoading = false;
  bool _clearAllChatsButtonLoading = false;
  bool _chatsCleared = false;
  bool _exportChatsLoading = false;
  bool _chatsExported = false;

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
                child: const Text("Manage Storage",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            BeautifulButton(
              text: "Regenerate Private Key",
              textColor: Colors.black,
              spaceBetween: 10.0,
              color: const Color.fromARGB(220, 255, 255, 255),
              imagePath: 'assets/private_key.png',
              heightImage: 38.0,
              widthImage: 38.0,
              onPressed: () async => await _regenerateEncryptionKeys(context),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            BeautifulButton(
              text: "Export Chats",
              textColor: Colors.black,
              spaceBetween: 10.0,
              color: const Color.fromARGB(220, 255, 255, 255),
              imagePath: 'assets/export_chats.png',
              heightImage: 38.0,
              widthImage: 38.0,
              onPressed: () async => await _exportChats(context),
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

  Future<void> _regenerateEncryptionKeys(BuildContext context) async {
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
      final user = await _authViewModel.regenerateEncryption();
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

  Future<void> _exportChats(BuildContext context) async {
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
      String? userId;
      userId = _authViewModel.signedInUser?.id;
      if (userId == null) {
        throw Exception("User not signed in");
      }
      final dbPath = _dataSource.getDatabasePath();
      final password = await showDialog<String>(
          context: context, builder: _buildDialog, barrierDismissible: true);
      if (password != null && password.length >= 8 && password.length < 16) {
        final encryptedFileBytes = MiscellaneousViewmodel.encrypt(
            password, userId, await File(dbPath).readAsBytes());
        final outputPath = await FilePicker.platform.saveFile(
            dialogTitle: "Please select output file to save database",
            fileName: "secuchat.db.secrypt",
            bytes: encryptedFileBytes,
            type: FileType.custom);
        if (outputPath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Unable to save database!")));
        } else {
          _chatsExported = true;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("File saved!")));
        }
      }
    } catch (e) {
      print("An error occurred while saving the file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to save database! ${e.toString()}")));
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

  Widget _buildDialog(BuildContext context) {
    final controllerPassword = TextEditingController();
    final controllerConfirmPassword = TextEditingController();
  
    final formKey = GlobalKey<FormState>();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => false,
      child: AlertDialog(
        backgroundColor: kBackgroundColor,
        shape: BeveledRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(20)),
        title: Text("Backup"),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                MyFormField(
                    prefixIcon: Icons.password,
                    infoBox: "Password",
                    parentSetState: setState,
                    heightFactor: 0.8,
                    keyBoardType: TextInputType.visiblePassword,
                    obscureText: true,
                    textEditingController: controllerPassword,
                    validator: (value) {
                      //! Setstate is missing, can introduce new bugs
                      return validatePasswordPattern(value);
                    },
                    suffixIcon: suffixIcon(
                        controllerPassword.text, validatePasswordPattern),
                    formField: 0),
                MyFormField(
                    prefixIcon: Icons.password,
                    infoBox: "Confirm Password",
                    heightFactor: 0.8,
                    parentSetState: setState,
                    keyBoardType: TextInputType.visiblePassword,
                    obscureText: true,
                    textEditingController: controllerConfirmPassword,
                    validator: (value) {
                      //! Setstate is missing, can introduce new bugs
                      return validateConfirmPassword(
                          controllerPassword.text, value ?? '');
                    },
                    suffixIcon: suffixIcon(controllerConfirmPassword.text, (_) {
                      return validateConfirmPassword(controllerPassword.text,
                          controllerConfirmPassword.text);
                    }),
                    formField: 1),
                Text(
                  "Please make sure, you remember this password, it won't be possible ti recover your chats if you forget it",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
                // TextFormField(
                //   controller: controllerConfirmPassword,
                //   decoration: InputDecoration(
                //     hint: Text("Confirm Password"),
                //   ),
                //   obscureText: true,
                //   validator: (value) {
                //     return controllerPassword.text != value
                //         ? "Passwords do not match"
                //         : null;
                //   },
                // ),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
            child: Text("Encrypt"),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controllerPassword.text);
              }
            },
          )
        ],
      ),
    );
  }

  String? validatePasswordPattern(String? password) {
    /**r'^
      (?=.*[A-Z])       // should contain at least one upper case
     (?=.*[a-z])       // should contain at least one lower case
    (?=.*?[0-9])      // should contain at least one digit
      (?=.*?[!@#\$&*~]) // should contain at least one Special character
      .{8,}             // Must be at least 8 characters in length  
$ */
    if (password != null &&
        password.contains(RegExp(
            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&_*~]).{8,16}$'))) {
            
      return null;
    }

    return "Password is not strong enough";
  }

  String? validateConfirmPassword(String password, String confPassword) {
    if (password == confPassword) {
      return null;
    }
    return "Password and Confirm Passwords do not match";
  }
}
