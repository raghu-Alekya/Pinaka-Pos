import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class Logout extends StatelessWidget {
  final VoidCallback funCloseShift;
  final VoidCallback funLogout;
  final VoidCallback funCancel;
  final bool isDarkMode;

  const Logout({
    Key? key,
    required this.funLogout,
    required this.funCancel,
    required this.funCloseShift,
    this.isDarkMode = false,
  }) : super(key: key);

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer tilted border
              Transform.rotate(
                angle: 0.04,
                child: Container(
                  width: 380,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF434242)
                          : Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),

              // Inner dialog
              Transform.rotate(
                angle: -0.04,
                child: Container(
                  width: 370,
                  height: 400,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Image.asset("assets/logout.png", width: 80, height: 80),
                        const SizedBox(height: 20),

                        Text(
                          "Are you sure?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "Choose what you’d like to do before leaving.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Swipe button
                        SizedBox(
                          width: 260,
                          child: SwipeButton(
                            thumb: Container(
                              width: 70,
                              height: 35,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF033495), Color(0xFF3CCBFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.double_arrow_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            borderRadius: BorderRadius.circular(18),
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            height: 42,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF033495), Color(0xFF3CCBFF)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Swipe to Close Shift",
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            onSwipe: funCloseShift,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF6F6F6),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 16),
                              ),
                              onPressed: funCancel,
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0XFFFE6464),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 16),
                              ),
                              onPressed: funLogout,
                              child: const Text("Logout",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showLogoutDialog(context);
    });
    return const SizedBox.shrink();
  }
}