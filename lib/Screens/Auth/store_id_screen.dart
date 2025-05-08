import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Screens/Auth/login_screen.dart';
import '../../Blocs/Auth/login_bloc.dart';
import '../../Constants/text.dart';
import '../../Database/db_helper.dart';
import '../../Database/user_db_helper.dart';
import '../../Helper/api_response.dart';
import '../../Models/Auth/login_model.dart';
import '../../Repositories/Auth/login_repository.dart';
import '../../Widgets/widget_custom_num_pad.dart';
import '../../Widgets/widget_loading.dart';
import '../Home/fast_key_screen.dart';
import '../../Widgets/widget_error.dart';

class StoreIdScreen extends StatefulWidget { // Build #1.0.16
  const StoreIdScreen({super.key});

  @override
  _StoreIdScreenState createState() => _StoreIdScreenState();
}

class _StoreIdScreenState extends State<StoreIdScreen> {
  final List<String> _password = List.filled(6, "");
  late LoginBloc _bloc;
  final UserDbHelper _userDbHelper = UserDbHelper();
  final TextEditingController _storeIdController = TextEditingController();
  bool _isStoreIdEmpty = true;

  final _formKey = GlobalKey<FormState>();

  String? _snackBarMessage;

  @override
  void initState() {
    super.initState();
    _bloc = LoginBloc(LoginRepository());
    //  _checkExistingUser(); // Un comment this line if auto login needed
  }

  Future<void> _checkExistingUser() async {
    bool isLoggedIn = await _userDbHelper.isUserLoggedIn();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FastKeyScreen()),
      );
    }
  }

  // void _updatePassword(String value) {
  //   for (int i = 0; i < _password.length; i++) {
  //     if (_password[i].isEmpty) {
  //       setState(() {
  //         _password[i] = value;
  //       });
  //       if (kDebugMode) {
  //         print("Password updated: $_password");
  //       }
  //
  //       // Auto-submit when 6 digits are entered
  //       // if (i == 5) {
  //       //   _handleLogin();
  //       // }
  //       break;
  //     }
  //   }
  // }
  //
  // void _deletePassword() {
  //   for (int i = _password.length - 1; i >= 0; i--) {
  //     if (_password[i].isNotEmpty) {
  //       setState(() {
  //         _password[i] = "";
  //       });
  //       if (kDebugMode) {
  //         print("Password deleted: $_password");
  //       }
  //       break;
  //     }
  //   }
  // }
  //
  // // Clear all fields with animation by resetting them one by one
  // void _clearPassword() {
  //   setState(() {
  //     // Clear the fields one by one to trigger the animation on each field
  //     for (int i = 0; i < _password.length; i++) {
  //       _password[i] = ""; // Reset each field with animation
  //     }
  //   });
  //   if (kDebugMode) {
  //     print("Password cleared: $_password");
  //   }
  // }
  //
  // bool _validatePin() { // Build #1.0.13
  //   if (_password.any((digit) => digit.isEmpty)) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please enter 6-digit PIN',
  //         style: TextStyle(color: Colors.red),
  //       ),),
  //     );
  //     return false;
  //   }
  //   return true;
  // }
  //
  // void _handleLogin() {
  //   if (!_validatePin()) return;
  //
  //   final pin = _password.join();
  //   _bloc.fetchLoginToken(LoginRequest(pin));
  // }

  @override
  Widget build(BuildContext context) {
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: Row(
        children: [
          // Left Side - Logo Section
          Expanded(
            flex: 1,
            child: Container(
              color: const Color(0xFF1E2745),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/app_logo.svg',
                  height: 150,
                ),
              ),
            ),
          ),

          // Right Side - Login Interface
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Please Enter Your Store ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: isPortrait
                          ? MediaQuery.of(context).size.width / 2.5
                          : MediaQuery.of(context).size.width / 3,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _storeIdController,
                        decoration: InputDecoration(
                          hintText: 'Store ID',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.white, width: 1.0, style: BorderStyle.none),
                          ),
                          // errorBorder: OutlineInputBorder(
                          //   borderRadius: BorderRadius.all(Radius.circular(5)),
                          //   borderSide: BorderSide(color: Colors.red),
                          // ),
                          // focusedBorder: UnderlineInputBorder(
                          //   borderSide: BorderSide(color: Colors.white),
                          // ),
                        ),
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a Store ID';
                          }
                          // Add custom validation logic here
                          return null; // Return null when input is valid
                        }, // This implementation will show error messages below the TextField when validation fails,
                           // and only allow navigation to the LoginScreen when validation passes.
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: isPortrait
                          ? MediaQuery.of(context).size.width / 4
                          : MediaQuery.of(context).size.width / 3,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _storeIdController.text.isNotEmpty) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2745),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
