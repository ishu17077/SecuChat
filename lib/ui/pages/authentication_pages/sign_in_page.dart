// import 'package:secuchat/ui/pages/authentication_pages/reusable_widgets/app_back_button.dart';
// import 'package:secuchat/ui/pages/authentication_pages/reusable_widgets/my_form_field.dart';
// import 'package:secuchat/ui/pages/authentication_pages/sign_up_page.dart';
// import 'package:secuchat/ui/pages/chatPage/chat_page.dart';
// import 'package:secuchat/server_functions/add_new_user.dart';
// import 'package:secuchat/server_functions/existing_user.dart';
// import 'package:secuchat/unit_components.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class SignInPage extends StatefulWidget {
//   const SignInPage({super.key});

//   @override
//   State<SignInPage> createState() => _SignInPageState();
// }

// class _SignInPageState extends State<SignInPage> {
//   int formFieldSelector = 69;

//   final TextEditingController _emailController = TextEditingController();

//   final TextEditingController _passwordController = TextEditingController();

//   bool _isEmailValid = false;

// //? regex expressin for containing only numbers
//   bool _passCheck = false;

//   late final GlobalKey<FormState> _formKey = GlobalKey();
//   @override
//   void initState() {
//     _emailController.addListener(() {
//       _validateEmail(_emailController.text);
//     });
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBackgroundColor,
//       body: Padding(
//         padding: const EdgeInsets.all(17.0),
//         child: Form(
//           key: _formKey,
//           child: ScrollConfiguration(
//             behavior: const ScrollBehavior().copyWith(overscroll: false),
//             child: SingleChildScrollView(
//               physics: const ClampingScrollPhysics(),
//               child: SafeArea(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.016106397),
//                     Padding(
//                       padding: EdgeInsets.only(
//                           top: MediaQuery.of(context).size.height * 0.0069),
//                       child: AppBackButton(
//                           onPressed: () => Navigator.pop(context)),
//                     ),
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.030956266),
//                     Padding(
//                       padding: EdgeInsets.only(
//                         left: MediaQuery.of(context).size.width * 0.030,
//                       ),
//                       child: const Text(
//                         "Sign In",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white,
//                           fontSize: 38,
//                         ),
//                       ),
//                     ),
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.030956266),
//                     Padding(
//                       padding: EdgeInsets.only(
//                         left: MediaQuery.of(context).size.width * 0.035,
//                       ),
//                       child: const Text(
//                         "Please fill the inputs below here",
//                         style: TextStyle(
//                           color: kSubHeadingColor,
//                           fontSize: 15.0,
//                         ),
//                       ),
//                     ),
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.030956266),
//                     MyFormField(
//                       infoBox: 'EMAIL',
//                       keyBoardType: TextInputType.emailAddress,
//                       formField: 3,
//                       onFocusChanged: (value) {
//                         if (value) {
//                           setState(() {
//                             formFieldSelector = 3;
//                           });
//                         }
//                       },
//                       prefixIcon: Icons.mail_outline,
//                       onPressed: () => setState(() {
//                         formFieldSelector = 3;
//                       }),
//                       textEditingController: _emailController,
//                       validator: (value) =>
//                           _isEmailValid ? null : 'Fuck you biyach',
//                       suffixIcon: _isEmailValid
//                           ? greenCheckMark
//                           : _emailController.text.isEmpty
//                               ? null
//                               : redCross,
//                     ),
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.030956266),
//                     MyFormField(
//                         infoBox: 'PASSWORD',
//                         textEditingController: _passwordController,
//                         keyBoardType: TextInputType.visiblePassword,
//                         formField: 4,
//                         obscureText: true,
//                         prefixIcon: Icons.password_rounded,
//                         onPressed: () => setState(() {
//                               formFieldSelector = 3;
//                             }),
//                         suffixIcon: _passCheck
//                             ? greenCheckMark
//                             : _passwordController.text.isEmpty
//                                 ? null
//                                 : redCross,
//                         onFocusChanged: (value) {
//                           if (value) {
//                             setState(() {
//                               formFieldSelector = 4;
//                             });
//                           }
//                         },
//                         validator: (value) => null),
//                     SizedBox(
//                         height:
//                             MediaQuery.of(context).size.height * 0.030956266),
//                     Center(
//                         child: sexyTealButton(context, onPressed: () {
//                       _formKey.currentState?.save();
//                       if (_formKey.currentState!.validate()) {
//                         FirebaseAuth.instance.signOut();
//                         try {
//                           ExistingUser.signInExistingUserWithEmailandPassword(
//                                   _emailController.text.toLowerCase(),
//                                   _passwordController.text)
//                               .then((value) {
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => ChatPage()));
//                           });
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                   content: Text("Invalid Email/Password")));
//                         }
//                       }
//                     })),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _validateEmail(String? email) {
//     if ((email?.length ?? 0) != 0 && emailRegExp.hasMatch(email ?? '')) {
//       setState(() {
//         _isEmailValid = true;
//       });
//     } else {
//       setState(() {
//         _isEmailValid = false;
//       });
//     }
//   }

  // Widget sexyTealButton(context, {required VoidCallback? onPressed}) {
  //   return ElevatedButton(
  //     style: ButtonStyle(
  //       backgroundColor: WidgetStateProperty.all(kSexyTealColor),
  //       minimumSize: WidgetStateProperty.all(Size(
  //           MediaQuery.of(context).size.width * 0.55,
  //           MediaQuery.of(context).size.height * 0.075)),
  //       elevation: WidgetStateProperty.all(5.0),
  //       shape: WidgetStateProperty.all(
  //           RoundedRectangleBorder(borderRadius: BorderRadius.circular(35))),
  //     ),
  //     onPressed: onPressed,
  //     child: const Text(
  //       "SIGN IN",
  //       style: TextStyle(
  //         color: kBackgroundColor,
  //         fontSize: 15,
  //       ),
  //     ),
  //   );
  // }
// }
