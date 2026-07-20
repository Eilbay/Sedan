// import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
// import 'package:optombai/firebase/google_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// class SocialsButton extends StatelessWidget {
//   SocialsButton({super.key, required this.title, required this.icon});
//
//   final String title;
//   final String icon;
//   final GoogleAuth googleSingIn = GoogleAuth();
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () async {
//         var auth = context.read<AuthCubit>();
//         try {
//           var token = await googleSingIn.signIn();
//           auth.googleAuth(token);
//         } catch (e) {
//           print(e);
//         }
//       },
//       style: ElevatedButton.styleFrom(
//         elevation: 0,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         side: const BorderSide(
//           width: 1.0.w,
//           color: Colors.black,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20.0),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image(
//             image: AssetImage(icon),
//           ),
//           const SizedBox(
//             width: 10.w,
//           ),
//           Text(title),
//         ],
//       ),
//     );
//   }
// }
