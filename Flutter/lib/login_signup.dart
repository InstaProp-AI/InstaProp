import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  // signup extras
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  String gender = 'Male';

  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    String? err;
    if (isLogin) {
      err = await authState.login(email.text, password.text);
    } else {
      err = await authState.signup({
        'firstName': firstName.text,
        'lastName': lastName.text,
        'phoneNumber': phone.text,
        'email': email.text,
        'gender': gender,
        'hashedPassword': password.text,
      });
    }
    if (!mounted) return;
    setState(() => loading = false);
    if (err == null) {
      Navigator.pop(context, true);
    } else {
      setState(() => error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null)
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  if (!isLogin) ...[
                    TextFormField(
                      controller: firstName,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: lastName,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => gender = v ?? 'Male'),
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                  ],
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: Text(isLogin ? 'Login' : 'Create account'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? 'Need an account? Sign up'
                          : 'Have an account? Login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> requireLogin(BuildContext context) async {
  if (authState.isLoggedIn) return true;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      title: const Text('Please log in'),
      content: const Text('You need to log in to access this feature.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx, true);
            final ok = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginSignupPage()),
            );
            // ok true means logged in
          },
          child: const Text('Login / Sign up'),
        ),
      ],
    ),
  );
  if (result == true) {
    // After dialog, check again
    return authState.isLoggedIn;
  }
  return false;
}
