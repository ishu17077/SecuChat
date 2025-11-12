import 'dart:io';

import 'package:chat/chat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:secuchat/composition_root.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/ui/helpers/suffix_icon.dart';
import 'package:secuchat/ui/widgets/beautiful_button.dart';
import 'package:secuchat/ui/widgets/my_form_field.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/miscellaneous/miscellaneous_viewmodel.dart';

class AccountInfo extends StatefulWidget {
  final User user;
  final IDataSource _dataSource;
  const AccountInfo(
      {required this.user, required IDataSource datasource, super.key})
      : _dataSource = datasource;

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Welcome!", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                MyFormField(
                  prefixIcon: Icons.account_circle_outlined,
                  textEditingController: _nameController,
                  validator: nameValidator,
                  suffixIcon: suffixIcon(_nameController.text, nameValidator),
                  formField: 0,
                ),
                MyFormField(
                    prefixIcon: Icons.mark_email_read_outlined,
                    textEditingController: _emailController,
                    validator: (_) => null,
                    suffixIcon:
                        Icon(Icons.ac_unit_sharp, color: Colors.blueAccent),
                    formField: 1,
                    disabled: true),
                MyFormField(
                    prefixIcon: Icons.supervised_user_circle_outlined,
                    textEditingController: _usernameController,
                    validator: (_) => null,
                    suffixIcon:
                        Icon(Icons.ac_unit_sharp, color: Colors.blueAccent),
                    formField: 1,
                    disabled: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BeautifulButton(
                      text: "Account Options",
                      color: Colors.white,
                      imagePath: 'assets/account_recovery.png',
                      onPressed: () async {
                        navigatorKey.currentState?.push(MaterialPageRoute(
                          builder: (context) =>
                              CompositionRoot.composeManageStorageUi(),
                        ));
                      },
                    ),
                    BeautifulButton(
                      text: "Import Chats",
                      color: Colors.white,
                      imagePath: 'assets/import_chats.png',
                      onPressed: () async {
                        navigatorKey.currentState?.push(MaterialPageRoute(
                          builder: (context) =>
                              CompositionRoot.composeManageStorageUi(),
                        ));
                      },
                    ),
                  ],
                ),
              ],
            )),
      )),
    );
  }

  Future<void> importChats() async {
    try {
      final dbPath = widget._dataSource.getDatabasePath();
      String? password =
          await showDialog<String?>(context: context, builder: _buildDialog);
      if (password != null && password.isNotEmpty) {
        password = "${widget.user.id!}${password}";
        final fileRes = await FilePicker.platform.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: ["crypt"],
          dialogTitle: "Import database",
        );
        if (fileRes != null && fileRes.files.isNotEmpty) {
          final XFile dbCrypt = fileRes.files.first.xFile;
          if (dbCrypt.name.split(".").last != "secrypt") {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Invalid file selected")));
            return;
          }
          Uint8List dbBytes = MiscellaneousViewmodel.decrypt(
              password, widget.user.id!, await dbCrypt.readAsBytes());

          
        
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Password cannot be empty")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong, try again!")));
    }
  }

  String? nameValidator(String? name) {
    if (name == null || name.length < 4) {
      return "Name length ength cannot be smaller than 5";
    }
    return null;
  }

  Widget _buildDialog(BuildContext context) {
    final controllerPassword = TextEditingController();
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
                    infoBox: "Confirm Password",
                    heightFactor: 0.8,
                    keyBoardType: TextInputType.visiblePassword,
                    obscureText: true,
                    textEditingController: controllerPassword,
                    validator: (value) {
                      if (controllerPassword.text.isEmpty) {
                        return "Password cannot be empty!";
                      }
                      return null;
                    },
                    suffixIcon: null,
                    formField: 0),
                Text(
                  "Enter the correct password",
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
            child: Text("Decrypt!"),
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
}
