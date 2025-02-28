import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLogin = true;
  String? errorMessage;
  bool isLoading = false;

  void _authenticate() async {
    setState(() => isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Please enter email and password";
        isLoading = false;
      });
      return;
    }

    String? result;
    if (isLogin) {
      result = await AuthService().loginUser(email, password);
    } else {
      result = await AuthService().registerUser(email, password);
    }

    setState(() {
      errorMessage = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(errorMessage!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isLogin ? 'Login' : 'Register'),
                  ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  errorMessage = null;
                });
              },
              child: Text(isLogin ? "Don't have an account? Register" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
