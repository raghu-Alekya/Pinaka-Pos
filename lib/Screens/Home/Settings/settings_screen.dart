import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinaka_pos/Screens/Home/Settings/printer_setup_screen.dart';
import 'package:pinaka_pos/Utilities/printer_settings.dart';
import 'package:provider/provider.dart';

import '../../../Constants/text.dart';
import '../../../Database/db_helper.dart';
import '../../../Database/user_db_helper.dart';
import '../../../Helper/Extentions/theme_notifier.dart';
import '../../../Preferences/pinaka_preferences.dart';
import '../../../Repositories/Auth/store_validation_repository.dart';

class SettingsScreen extends StatefulWidget { // Build #1.0.6 - Added Settings Screen
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String keyboardType = "Virtual";
  bool quickProductAdd = false;
  bool outOfStockManage = true;
  String cacheDuration = "Never";
  String? appearance;
  bool enableGST = false;
  String selectedLanguage = "English";
  bool isRetailer = true;
  String layoutSelection = ""; // Default layout
  final StoreValidationRepository _storeValidationRepository = StoreValidationRepository();
  File? _selectedIcon;

  TextEditingController nameController = TextEditingController();
  TextEditingController contactNoController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController companyNameController = TextEditingController();
  TextEditingController gstInController = TextEditingController();
  TextEditingController headerController = TextEditingController();
  TextEditingController footerController = TextEditingController();
  TextEditingController deviceIdController = TextEditingController();
  TextEditingController posNoController = TextEditingController();
  final PinakaPreferences _preferences = PinakaPreferences(); // Create an instance

  @override
  void initState() {
    super.initState();
    _loadUserDataFromDB();
    _loadAppThemeMode(); // Appearance light/dark/system
    _loadSavedLayout();
  }

  Future<void> _loadUserDataFromDB() async { // Build #1.0.13 : now user data loads from user table DB
    try {
      final userData = await UserDbHelper().getUserData();
      final storeData = await UserDbHelper().getStoreValidationData(); //Build #1.0.54: added
      final deviceDetails = await _storeValidationRepository.getDeviceDetails(); // Fetch device details

      if (userData != null) {
        nameController.text       = userData[AppDBConst.userDisplayName] ?? "Unknown Name";
        emailController.text      = userData[AppDBConst.userEmail] ?? "test@pinaka.com";
        deviceIdController.text   = deviceDetails['device_id'] ?? "unknown"; // device ID

        if (kDebugMode) {
          print("#### Loaded user data into controllers: $userData");
        }
      }

      if (storeData != null) { //Build #1.0.54: added
        if (kDebugMode) {
          print("### TEST storeName : ${storeData[AppDBConst.storeName] ?? ""}");
          print("### TEST licenseKey : ${storeData[AppDBConst.licenseKey] ?? ""}");
        }
        setState(() {
          contactNoController.text  = storeData[AppDBConst.storePhone] ?? "";
          companyNameController.text = storeData[AppDBConst.storeName] ?? "";
          gstInController.text = storeData[AppDBConst.licenseKey] ?? "";
          // Add subscription details to UI if needed
        });
      }

      if (kDebugMode) {
        print("#### Loaded user data: $userData");
        print("#### Loaded store data: $storeData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading user data: $e");
      }
    }
  }

  //Build #1.0.54: added load saved layout and update notifier
  Future<void> _loadSavedLayout() async {
    String? savedLayout = await _preferences.getSavedLayoutSelection();
    PinakaPreferences.layoutSelectionNotifier.value =
        savedLayout ?? SharedPreferenceTextConstants.navLeftOrderRight;
    if (kDebugMode) {
      print(
          "#### PinakaPreferences: Initialized with layout: ${PinakaPreferences.layoutSelectionNotifier.value}");
    }

    setState(() {
      layoutSelection = PinakaPreferences.layoutSelectionNotifier.value;
    });
  }

  Future<void> _loadAppThemeMode() async { // Build #1.0.9 : By default dark theme getting selected on launch even after changing from settings
    String? savedTheme = await _preferences.getSavedAppThemeMode() ?? ThemeMode.light.toString();

    setState(() {
      appearance = savedTheme == ThemeMode.dark.toString() ? TextConstants.darkText : TextConstants.lightText;
    });

    if (kDebugMode) {
      print("#### _loadAppThemeMode : $appearance");
    }
  }

  // Build #1.0.108: for image selection
  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final image = await decodeImageFromList(await imageFile.readAsBytes());
      if (image.width <= 128 && image.height <= 128 && pickedFile.path.endsWith('.png')) {
        setState(() {
          _selectedIcon = imageFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a PNG image with max 128x128')),
        );
      }
    }
  }

  // Build #1.0.108: Added to save action in saveButton onPressed
  Future<void> _saveReceiptSettings() async {
    final userData = await UserDbHelper().getUserData();
    if (userData != null) {
      Map<String, dynamic> receiptSettings = {
        TextConstants.userId: userData[AppDBConst.userId],
        TextConstants.iconPath: _selectedIcon?.path,
        TextConstants.conHeaderText: headerController.text,
        TextConstants.conFooterText: footerController.text,
      };
      await UserDbHelper().saveReceiptSettings(receiptSettings);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contactNoController.dispose();
    emailController.dispose();
    deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeHelper = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      backgroundColor: themeHelper.getTheme(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeHelper.getTheme(context).textTheme.bodyLarge?.color),
          onPressed: () {
            Navigator.pop(context); // Return true to indicate a refresh
          },
        ),
        title: Text(
          TextConstants.settingsHeaderText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeHelper.getTheme(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              _saveReceiptSettings(); // Build #1.0.108: Save Receipt settings into user db table
              Navigator.pop(context);
            },
            child: Text(TextConstants.saveChangesBtnText, style: TextStyle(color: Colors.black)),
          ),
          SizedBox(width: 16),
        ],
        backgroundColor: themeHelper.getTheme(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCombinedSections(themeHelper),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedSections(ThemeNotifier themeHelper) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side Column
          Expanded(
            child: Column(
              children: [
                _buildPersonalInfoSection(),
                Divider(color: Colors.grey[800], thickness: 1),
                _buildDeviceDetailsSection(),
                Divider(color: Colors.grey[800], thickness: 1),
                _buildAppearanceSection(themeHelper),
                Divider(color: Colors.grey[800], thickness: 1),
                _buildCacheDurationSection(),
              ],
            ),
          ),
          // Vertical Divider between left and right columns
          VerticalDivider(
            color: Colors.grey[800],
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          SizedBox(width: 16),
          // Right Side Column
          Expanded(
            child: Column(
              children: [
                _buildReceiptSettingSection(),
                Divider(color: Colors.grey[800], thickness: 1),
                // _buildTaxesAndLanguageSection(),
                // Divider(color: Colors.grey[800], thickness: 1),
                _buildPrinterSettingsSection(),
                Divider(color: Colors.grey[800], thickness: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TextConstants.personalInfoText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Text(TextConstants.personalInfoSubText,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        SizedBox(height: 16),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 80,
                width: 80,
                color: Colors.grey[800],
                child: Icon(Icons.perm_identity, color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TextConstants.userText, style: TextStyle(fontSize: 16, color: Colors.white)),
                Text(TextConstants.administratorText,
                    style: TextStyle(fontSize: 12, color: Colors.tealAccent)),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    label: TextConstants.fullNameText, controller: nameController)),
            SizedBox(width: 10),
            Expanded(
                child: _buildTextField(
                    label: TextConstants.contactNoText, controller: contactNoController)),
          ],
        ),
        _buildTextField(label: TextConstants.emailText, controller: emailController),
        // _buildTextField(
        //     label: "Subscription Type",
        //     controller: TextEditingController(text: storeData?[AppDBConst.subscriptionType] ?? ""),
        //     isReadOnly: true),
        // _buildTextField(
        //     label: "Expiration Date",
        //     controller: TextEditingController(text: storeData?[AppDBConst.expirationDate] ?? ""),
        //     isReadOnly: true),
      ],
    );
  }

  // Build #1.0.108: Modified _buildReceiptSettingSection
  Widget _buildReceiptSettingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TextConstants.receiptText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8),
        Text(TextConstants.ownReceiptText,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: _pickIcon,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedIcon != null
                    ? Image.file(_selectedIcon!, fit: BoxFit.cover)
                    : Icon(Icons.image, color: Colors.white70),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                  label: TextConstants.companyNameText,
                  controller: companyNameController,
                  hintText: TextConstants.companyNameHintText),
            ),
          ],
        ),
        _buildTextField(label: TextConstants.gstinText, controller: gstInController, hintText: TextConstants.gstinHintText),
        _buildTextField(
            label: TextConstants.headerText,
            hintText: TextConstants.headerHintText,
            controller: headerController),
        _buildTextField(
            label: TextConstants.footerText,
            hintText: TextConstants.footerHintText,
            controller: footerController),
      ],
    );
  }

  Widget _buildDeviceDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TextConstants.deviceDetailsText,
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text(TextConstants.idPOSText,
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Handle Copy Token action
              },
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text(TextConstants.copyTokenBtnText, style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
            label: TextConstants.deviceIdText,
            controller: deviceIdController,
            isReadOnly: true),
        SizedBox(height: 16),
        _buildTextField(label: TextConstants.posNumberText, hintText: TextConstants.posNumberHintText),
        SizedBox(height: 16),
        Text(TextConstants.posForText, style: TextStyle(fontSize: 14, color: Colors.white70)),
        _buildToggleButtons(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTaxesAndLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TextConstants.taxesText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(TextConstants.manageTaxesText, style: TextStyle(color: Colors.grey)),
          trailing: Text(TextConstants.addBtnText, style: TextStyle(color: Colors.cyan)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(TextConstants.enableGSTText, style: TextStyle(color: Colors.white)),
          trailing: Switch(
              value: enableGST,
              onChanged: (value) {
                setState(() => enableGST = value);
              }),
        ),
        Divider(color: Colors.grey[800], height: 32),
        Text(TextConstants.languageText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold , color: Colors.white)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(TextConstants.chooseLanText, style: TextStyle(color: Colors.grey)),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: selectedLanguage,
              underline: SizedBox(),
              dropdownColor: Colors.grey[900],
              style: TextStyle(color: Colors.white),
              items: ["English", "Spanish", "French"]
                  .map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang, style: TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedLanguage = value!);
              },
              icon: Icon(Icons.arrow_drop_down, color: Colors.white), // Dropdown icon color
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(ThemeNotifier themeManager) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TextConstants.appearanceText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(TextConstants.screenModeText,
            style: TextStyle(fontSize: 14, color: Colors.white)),
        Row(
          children: [
            _buildAppearanceOption(TextConstants.lightText, themeManager),
            _buildAppearanceOption(TextConstants.darkText, themeManager),
          ],
        ),
        SizedBox(height: 16),
        Text(TextConstants.layoutSelectionHeader,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Column(
          children: [
            _buildLayoutOption(TextConstants.layoutNavLeftOrderRight, SharedPreferenceTextConstants.navLeftOrderRight),
            _buildLayoutOption(TextConstants.layoutNavRightOrderLeft, SharedPreferenceTextConstants.navRightOrderLeft),
            _buildLayoutOption(TextConstants.layoutNavBottomOrderLeft, SharedPreferenceTextConstants.navBottomOrderLeft),
          ],
        ),
        // Text(TextConstants.selectKeyboardText, // Build #1.0.15 : removed Keyboard type UI
        //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        // Row(
        //   children: [
        //     _buildRadioOption(TextConstants.virtualText),
        //     _buildRadioOption(TextConstants.systemText),
        //     _buildRadioOption(TextConstants.bothText),
        //   ],
        // ),
        _buildSwitchOption(TextConstants.quickProAddText, quickProductAdd, (value) {
          setState(() => quickProductAdd = value);
        }),
        _buildSwitchOption(TextConstants.outOfStockMngText, outOfStockManage, (value) {
          setState(() => outOfStockManage = value);
        }),
      ],
    );
  }

  //Build #1.0.54: Add _buildLayoutOption
  Widget _buildLayoutOption(String title, String value) {
    return Row(
      children: [
        Radio(
          value: value,
          groupValue: layoutSelection,
          onChanged: (value) {
            setState(() => layoutSelection = value.toString());
            _preferences.saveLayoutSelection(value.toString()); // This updates the notifier
          },
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return Colors.white;
          }),
        ),
        Text(title, style: TextStyle(color: Colors.white)),
      ],
    );
  }
  var _printerSettings =  PrinterSettings();
  Widget _buildPrinterSettingsSection() {
    var name = _printerSettings.selectedPrinter?.deviceName ?? '';
    var connection = _printerSettings.selectedPrinter?.state ?? false;

    if (kDebugMode) {
      print("SettingScreen - printer ${_printerSettings.selectedPrinter}, name: $name, connection: $connection");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              children: [
                Text(TextConstants.printerSettText,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(TextConstants.connectedPrintText,
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            Spacer(),
            _printerSettings.selectedPrinter != null ? SizedBox() : ElevatedButton(
              onPressed: () {
                /// call printer setup screen
                if (kDebugMode) {
                  print("call printer setup screen");
                }
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PrinterSetup(),
                )).then((result) {
                  if (result == 'refresh') {
                    _printerSettings.loadPrinter();
                    setState(() {
                      // Update state to refresh the UI
                      if (kDebugMode) {
                        print("SettingScreen - printer setup is done, connected printer is ${_printerSettings.selectedPrinter?.deviceName}");
                      }
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00FFAA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text(
                TextConstants.addBtnText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 10),
        ///Todo: show connected printer or Add printer button
        _printerSettings.selectedPrinter != null
            ?
        Center(child: Row(
          children: [
            Text(name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
            ),),
            Spacer(),
            Icon(
              Icons.check_circle,
              color: ThemeNotifier.buttonDark,
              size: 25,
            ),
          ],
        ),)
            :
        SizedBox(),
        // Center(
        //   child: Column(
        //     children: [
        //       SvgPicture.asset(
        //         'assets/svg/password_placeholder.svg', // Replace with actual asset path
        //         width: 120,
        //         height: 120,
        //       ),
        //       SizedBox(height: 20),
        //       Text(
        //         TextConstants.noPrinterText,
        //         style: TextStyle(
        //           color: Colors.white,
        //           fontSize: 18,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //       SizedBox(height: 10),
        //       // Text(
        //       //   TextConstants.add3PrintersText,
        //       //   style: TextStyle(
        //       //     color: Colors.grey,
        //       //     fontSize: 14,
        //       //   ),
        //       // ),
        //       SizedBox(height: 20),
        //       ElevatedButton(
        //         onPressed: () {
        //           /// call printer setup screen
        //           if (kDebugMode) {
        //             print("call printer setup screen");
        //           }
        //           Navigator.push(context, MaterialPageRoute(
        //             builder: (context) => PrinterSetup(),
        //           ));
        //         },
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: Color(0xFF00FFAA),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //           padding:
        //           const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        //         ),
        //         child: Text(
        //           TextConstants.addBtnText,
        //           style: TextStyle(
        //             color: Colors.black,
        //             fontSize: 16,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildCacheDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TextConstants.cacheText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(TextConstants.manageCacheText,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          Align(
            alignment: Alignment.topRight,
            child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.delete),
                label: Text(TextConstants.clearCacheText)),
          ),
        ]),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(TextConstants.cacheDurationText, style: TextStyle(fontSize: 14, color: Colors.white)),
            DropdownButton<String>(
              value: cacheDuration,
              dropdownColor: Colors.grey[800], // Dropdown background color
              onChanged: (String? newValue) {
                setState(() => cacheDuration = newValue!);
              },
              items:
              ["Never", "1 Day", "1 Week", "1 Month"].map((String value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.white), // Dropdown item text color
                  ),
                );
              }).toList(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.white)
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
      {String label = "",
        String hintText = "",
        bool isReadOnly = false,
        TextEditingController? controller}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            style: TextStyle(color: Colors.white), // Change text color here
            readOnly: isReadOnly,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: 300,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isRetailer = true);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isRetailer ? Colors.teal : Colors.black54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      TextConstants.retailerText,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isRetailer = false);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !isRetailer ? Colors.teal : Colors.black54,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      TextConstants.distributorText,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title) {
    return Row(
      children: [
        Radio(
          value: title,
          groupValue: keyboardType,
          onChanged: (value) {
            setState(() => keyboardType = value.toString());
          },
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white; // Change the inner circle color when selected
            }
            return Colors.white; // Change the border color when unselected
          }),
        ),
        Text(title, style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildSwitchOption(
      String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

// Update _buildAppearanceOption
  Widget _buildAppearanceOption(String title, ThemeNotifier themeManager) {
    return Row(
      children: [
        Radio(
          value: title,
          groupValue: appearance,
          onChanged: (value) {
            setState(() {
              appearance = value.toString();
              themeManager.setThemeMode( //Build #1.0.54: updated
                  appearance == TextConstants.lightText ? ThemeMode.light : ThemeMode.dark
              );
              _preferences.saveAppThemeMode(themeManager.themeMode);
            });
          },
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white; // Change the inner circle color when selected
            }
            return Colors.white; // Change the border color when unselected
          }),
        ),
        Text(title, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
