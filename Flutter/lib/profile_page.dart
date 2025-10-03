import 'package:flutter/material.dart';
import 'i18n.dart';

// Use the same color constants as main.dart for consistency
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kPrimary = Colors.green;
const Color kAccent = Color.fromARGB(255, 25, 71, 48);
const Color kText = Colors.black87;
const Color kGray = Color(0xFFF5F5F5);
const Color kWhite = Colors.white;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  // Dummy user data
  String name = "John Doe";
  String email = "john.doe@email.com";
  String phone = "+1 555 123 4567";
  String address = "123 Main St, Springfield, USA";
  String company = "Dream Homes Realty";
  String license = "RE-2025-12345";
  String bio =
      "Experienced real estate agent specializing in luxury properties and auctions.";
  String website = "www.johndoerealty.com";
  String joined = "March 2022";
  String totalBids = "34";
  String wonAuctions = "7";
  String rating = "4.8";
  String password = "********";

  final _formKey = GlobalKey<FormState>();

  // Controllers for editing
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController companyController;
  late TextEditingController licenseController;
  late TextEditingController bioController;
  late TextEditingController websiteController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: name);
    emailController = TextEditingController(text: email);
    phoneController = TextEditingController(text: phone);
    addressController = TextEditingController(text: address);
    companyController = TextEditingController(text: company);
    licenseController = TextEditingController(text: license);
    bioController = TextEditingController(text: bio);
    websiteController = TextEditingController(text: website);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    companyController.dispose();
    licenseController.dispose();
    bioController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  void saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        name = nameController.text;
        email = emailController.text;
        phone = phoneController.text;
        address = addressController.text;
        company = companyController.text;
        license = licenseController.text;
        bio = bioController.text;
        website = websiteController.text;
        isEditing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
    }
  }

  void changePassword() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Change password tapped!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: ValueListenableBuilder<AppLanguage>(
          valueListenable: appLanguage,
          builder: (_, lang, __) {
            final t = Strings(lang);
            return Text(
              t.profile,
              style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
            );
          },
        ),
        iconTheme: IconThemeData(color: kPrimary),
        actions: [
          // Language toggle
          ValueListenableBuilder<AppLanguage>(
            valueListenable: appLanguage,
            builder: (_, lang, __) {
              return PopupMenuButton<AppLanguage>(
                icon: const Icon(Icons.language, color: kPrimary),
                initialValue: lang,
                onSelected: (value) => appLanguage.value = value,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: AppLanguage.en,
                    child: Text(Strings(AppLanguage.en).languageEnglish),
                  ),
                  PopupMenuItem(
                    value: AppLanguage.ar,
                    child: Text(Strings(AppLanguage.ar).languageArabic),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit, color: kPrimary),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
                if (!isEditing) {
                  nameController.text = name;
                  emailController.text = email;
                  phoneController.text = phone;
                  addressController.text = address;
                  companyController.text = company;
                  licenseController.text = license;
                  bioController.text = bio;
                  websiteController.text = website;
                }
              });
            },
            tooltip: isEditing ? "Cancel" : "Edit Profile",
          ),
        ],
      ),
      body: ValueListenableBuilder<AppLanguage>(
        valueListenable: appLanguage,
        builder: (context, lang, _) {
          final t = Strings(lang);
          return Directionality(
            textDirection: t.direction,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: kPrimary,
                      child: Icon(Icons.person, size: 60, color: kWhite),
                    ),
                    const SizedBox(height: 18),
                    // Name
                    _profileField(
                      label: t.fullName,
                      value: name,
                      controller: nameController,
                      isEditing: isEditing,
                      icon: Icons.person,
                      validator: (v) => v == null || v.isEmpty
                          ? (t.isAr ? 'أدخل الاسم' : 'Enter your name')
                          : null,
                    ),
                    // Email
                    _profileField(
                      label: t.email,
                      value: email,
                      controller: emailController,
                      isEditing: isEditing,
                      icon: Icons.email,
                      validator: (v) => v == null || v.isEmpty
                          ? (t.isAr
                                ? 'أدخل البريد الإلكتروني'
                                : 'Enter your email')
                          : null,
                    ),
                    // Phone
                    _profileField(
                      label: t.phone,
                      value: phone,
                      controller: phoneController,
                      isEditing: isEditing,
                      icon: Icons.phone,
                      validator: (v) => v == null || v.isEmpty
                          ? (t.isAr ? 'أدخل الهاتف' : 'Enter your phone')
                          : null,
                    ),
                    // Address
                    _profileField(
                      label: t.address,
                      value: address,
                      controller: addressController,
                      isEditing: isEditing,
                      icon: Icons.location_on,
                    ),
                    // Company
                    _profileField(
                      label: t.company,
                      value: company,
                      controller: companyController,
                      isEditing: isEditing,
                      icon: Icons.business,
                    ),
                    // License
                    _profileField(
                      label: t.license,
                      value: license,
                      controller: licenseController,
                      isEditing: isEditing,
                      icon: Icons.verified,
                    ),
                    // Website
                    _profileField(
                      label: t.website,
                      value: website,
                      controller: websiteController,
                      isEditing: isEditing,
                      icon: Icons.language,
                    ),
                    // Bio
                    _profileField(
                      label: t.bio,
                      value: bio,
                      controller: bioController,
                      isEditing: isEditing,
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 18),
                    // Change Password
                    ListTile(
                      tileColor: kGray,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: Icon(Icons.lock, color: kPrimary),
                      title: Text(
                        t.password,
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(password, style: TextStyle(color: kText)),
                      trailing: TextButton(
                        onPressed: changePassword,
                        style: TextButton.styleFrom(foregroundColor: kPrimary),
                        child: Text(t.change),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statCard(t.totalBids, totalBids, Icons.gavel),
                        _statCard(
                          t.wonAuctions,
                          wonAuctions,
                          Icons.emoji_events,
                        ),
                        _statCard(t.rating, rating, Icons.star),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Joined
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: kAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          t.joined(joined),
                          style: TextStyle(color: kText, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Save Button
                    if (isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            t.saveChanges,
                            style: TextStyle(
                              color: kWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: isEditing
          ? TextFormField(
              controller: controller,
              validator: validator,
              maxLines: maxLines,
              style: TextStyle(color: kText, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: icon != null ? Icon(icon, color: kPrimary) : null,
                labelText: label,
                labelStyle: TextStyle(color: kPrimary),
                filled: true,
                fillColor: kGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          : ListTile(
              tileColor: kCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: icon != null ? Icon(icon, color: kPrimary) : null,
              title: Text(
                label,
                style: TextStyle(color: kAccent, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                value,
                style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kGray.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: kPrimary, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: kAccent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
