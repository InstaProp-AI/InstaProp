import 'package:flutter/material.dart';
import 'i18n.dart';

// Use the same color constants as main.dart for consistency
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kPrimary = Colors.green;
const Color kAccent = Colors.deepPurple;
const Color kText = Colors.black87;
const Color kGray = Color(0xFFF5F5F5);
const Color kWhite = Colors.white;

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController startPriceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController postedByController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String selectedCategory = 'Villa';

  final List<String> categories = [
    'Villa',
    'Apartment',
    'Cottage',
    'Condo',
    'Penthouse',
    'House',
    'Studio',
    'Cabin',
  ];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final t = Strings.of(context);
      final double? startPrice = double.tryParse(startPriceController.text);
      if (startPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid start price')),
        );
        return;
      }

      final Map<String, dynamic> newProperty = {
        'name': nameController.text,
        'category': selectedCategory,
        'startPrice': startPrice,
        'imageUrl': imageUrlController.text,
        'postedBy': postedByController.text,
        'address': addressController.text,
        'description': descriptionController.text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.propertyListedSuccess)),
      );
      Navigator.pop(context, newProperty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Strings.of(context);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          t.addProperty,
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kPrimary),
      ),
      body: Directionality(
        textDirection: t.direction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
              // Property Name
              _inputField(
                controller: nameController,
                label: t.propertyNameField,
                icon: Icons.home,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterPropertyName : null,
              ),
              // Category
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: kCard,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category, color: kPrimary),
                    labelText: t.categoryField,
                    labelStyle: const TextStyle(color: kPrimary),
                    filled: true,
                    fillColor: kGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    color: kText,
                    fontWeight: FontWeight.bold,
                  ),
                  items: categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(color: kText),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCategory = val);
                  },
                ),
              ),
              // Start Price
              _inputField(
                controller: startPriceController,
                label: t.startPriceField,
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterStartPrice : null,
              ),
              // Image URL
              _inputField(
                controller: imageUrlController,
                label: t.imageUrlField,
                icon: Icons.image,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterImageUrl : null,
              ),
              // Posted By
              _inputField(
                controller: postedByController,
                label: t.postedByField,
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterPosterName : null,
              ),
              // Address
              _inputField(
                controller: addressController,
                label: t.address,
                icon: Icons.location_on,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterAddress : null,
              ),
              // Description
              _inputField(
                controller: descriptionController,
                label: t.descriptionField,
                icon: Icons.info_outline,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? t.enterDescription : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add, color: kWhite),
                  label: Text(
                    t.listProperty,
                    style: TextStyle(
                      color: kWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: kText, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: kPrimary) : null,
          labelText: label,
          labelStyle: const TextStyle(color: kPrimary),
          filled: true,
          fillColor: kGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
