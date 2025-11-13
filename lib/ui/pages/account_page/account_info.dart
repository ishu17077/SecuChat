import 'dart:io';

import 'package:chat/chat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:secuchat/composition_root.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/data/factories/db_factory_impl.dart';
import 'package:secuchat/state_management/onboarding/onboarding_cubit.dart';
import 'package:secuchat/state_management/onboarding/onboarding_state.dart';
import 'package:secuchat/ui/helpers/suffix_icon.dart';
import 'package:secuchat/ui/pages/onboarding/onboarding_router.dart';
import 'package:secuchat/ui/widgets/beautiful_button.dart';
import 'package:secuchat/ui/widgets/my_form_field.dart';
import 'package:secuchat/ui/widgets/sexy_teal_button.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/miscellaneous/miscellaneous_viewmodel.dart';

class AccountInfo extends StatefulWidget {
  final User user;
  final IDataSource _dataSource;
  final IOnboardingRouter _router;
  const AccountInfo(
      {required this.user,
      required IDataSource datasource,
      required IOnboardingRouter router,
      super.key})
      : _dataSource = datasource,
        _router = router;

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    // TODO: implement initState
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _usernameController.text = widget.user.username;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0.0,
        title: Text(
          "Welcome!",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.09,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: PopScope(
        onPopInvokedWithResult: (didPop, result) => false,
        child: SafeArea(
            child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Center(
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    MyFormField(
                      prefixIcon: Icons.account_circle_outlined,
                      textEditingController: _nameController,
                      validator: nameValidator,
                      parentSetState: setState,
                      suffixIcon:
                          suffixIcon(_nameController.text, nameValidator),
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
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BeautifulButton(
                          widthFactor: 0.55,
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
                          widthFactor: 0.50,
                          color: Colors.white,
                          imagePath: 'assets/import_chats.png',
                          onPressed: importChats,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    BlocBuilder<OnboardingCubit, OnboardingState>(
                      builder: (context, state) {
                        if (state is OnboardingLoading) {
                          return CircularProgressIndicator();
                        }
                        return SexyTealButton(
                          text: "Save",
                          onPressed: () async {
                            await updateUser(_nameController.text);
                          },
                        );
                      },
                    )
                  ],
                )),
          ),
        )),
      ),
    );
  }

  Future<void> importChats() async {
    try {
      final fileRes = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ["secrypt"],
        dialogTitle: "Import database",
      );
      if (fileRes != null && fileRes.files.isNotEmpty) {
        final XFile dbCrypt = fileRes.files.first.xFile;
        if (dbCrypt.name.split(".").last != "secrypt") {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Invalid file selected")));
          return;
        }
        final password =
            await showDialog<String?>(context: context, builder: _buildDialog);
        if (password != null && password.isNotEmpty) {
          Uint8List dbBytes = MiscellaneousViewmodel.decrypt(
              password, widget.user.id!, await dbCrypt.readAsBytes());
          final directory = await getApplicationDocumentsDirectory();
          final File file = File("${directory.path}/temp.db");
          await file.writeAsBytes(dbBytes);
          await LocalDatabaseFactory().restoreFromDb(
              restoreDbPath: file.path,
              db: await LocalDatabaseFactory().getDatabase());

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Chat restore successful")));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Password cannot be empty")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Something went wrong, try again! ${e.toString()}")));
    }
  }

  Future<void> updateUser(String name) async {
    if (name == widget.user.name) {
      return widget._router.navigateHome(context, widget.user);
    }
    widget.user.name = name;
    final onboardingCubit = context.read<OnboardingCubit>();
    await onboardingCubit.connect(widget.user);
    onboardingCubit.stream.listen(
      (state) {
        if (state is OnboardingSuccess) {
          widget._router.navigateHome(context, widget.user);
        }
        if (state is OnboardingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Please check your internet connection and try again!")));
        }
      },
    );
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
                    infoBox: "Password",
                    parentSetState: setState,
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
                    color: kSubHeadingColor,
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
