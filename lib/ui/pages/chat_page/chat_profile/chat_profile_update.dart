// import 'dart:io';

// import 'package:secuchat/ui/pages/authentication_pages/email_and_password_page.dart';
// import 'package:secuchat/ui/pages/authentication_pages/reusable_widgets/my_form_field.dart';
// import 'package:secuchat/server_functions/add_new_user.dart';
// import 'package:secuchat/unit_components.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/material.dart';

// class ProfilePictureUpdate extends StatefulWidget {
//   const ProfilePictureUpdate({super.key});

//   @override
//   State<ProfilePictureUpdate> createState() => _ProfilePictureUpdateState();
// }

// class _ProfilePictureUpdateState extends State<ProfilePictureUpdate> {
//   TextEditingController nameTextEditingController = TextEditingController();
//   bool _isNameValid = false;
//   bool _showBottomBar = false;
//   File? imgFile;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PopScope(
//         canPop: true,
//         onPopInvoked: (lol) {
//           if (lol) {
//             _showBottomBar = false;
//           }
//         },
//         child: Column(
//           children: [
//             InkWell(
//               child: CircleAvatar(
//                 child: Image.network(AddNewUser.signedInUser?.photoURL ??
//                     'https://uxwing.com/wp-content/themes/uxwing/download/peoples-avatars/no-profile-picture-icon.png'),
//               ),
//               onTap: () {
//                 setState(() {
//                   _showBottomBar = true;
//                 });
//               },
//             ),
//             MyFormField(
//               onPressed: () {
//                 setState(() {
//                   formFieldSelector = 1;
//                 });
//               },
//               infoBox: 'Name',
//               prefixIcon: Icons.abc_rounded,
//               onFocusChanged: (bool fool) {},
//               textEditingController: nameTextEditingController,
//               validator: (name) => _isNameValid ? null : 'Fuck you biyack',
//               suffixIcon: _isNameValid ? greenCheckMark : redCross,
//               formField: 1,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton:
//           _showBottomBar ? bottomImageSelector() : const SizedBox(),
//     );
//   }

//   void _checkName() {
//     if (nameTextEditingController.text.length < 3) {
//       setState(() {
//         _isNameValid = true;
//       });
//     }
//     setState(() {
//       _isNameValid = false;
//     });
//   }

//   NavigationBar bottomImageSelector() {
//     return NavigationBar(
//       destinations: [
//         TextButton(
//           child: const Text('Select Image From Gallery!!'),
//           onPressed: () async {
//             final ImagePicker imagePicker = ImagePicker();
//             final XFile? img =
//                 await imagePicker.pickImage(source: ImageSource.gallery);
//             if (img != null) {
//               imgFile = File(img.path);
//             }
//           },
//         ),
//         TextButton(
//           child: const Text('Going bold, aren\'t we?'),
//           onPressed: () async {
//             final ImagePicker imagePicker = ImagePicker();
//             final XFile? img =
//                 await imagePicker.pickImage(source: ImageSource.camera);
//             if (img != null) {
//               imgFile = File(img.path);
//             }
//           },
//         ),
//         TextButton(
//           child: const Text('Mirror'),
//           onPressed: () {},
//         ),
//       ],
//     );
//   }
// }
