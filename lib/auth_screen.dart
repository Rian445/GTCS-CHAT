import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:lottie/lottie.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? toggleTheme; // Add toggle theme callback
  
  AuthScreen({this.toggleTheme});
  
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool isLogin = true;
  String? errorMessage;
  bool isLoading = false;
  
  // Animation controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Animation duration
    );
    
    // Auto-play the animation
    _animationController.forward();
    
    // Make animation loop
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _authenticate() async {
    setState(() => isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    if (isLogin) {
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = "Please enter email and password";
          isLoading = false;
        });
        return;
      }
    } else {
      // Registration requires name as well
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        setState(() {
          errorMessage = "Please enter name, email and password";
          isLoading = false;
        });
        return;
      }
    }

    String? result;
    if (isLogin) {
      result = await AuthService().loginUser(email, password);
    } else {
      result = await AuthService().registerUser(email, password, name);
    }

    setState(() {
      errorMessage = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme to check if dark mode is enabled
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Login" : "Register"),
        centerTitle: true,
        flexibleSpace: isDarkMode 
          ? null  // No gradient in dark mode
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
        // Add dark mode toggle button
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: widget.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Container(
                height: 200,
                child: Lottie.asset(
                  'assets/animation.json', // Path to your animation file
                  controller: _animationController,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Name Field (only shown during registration)
              if (!isLogin)
                Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              
              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              SizedBox(height: 15),
              
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              
              // Error Message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                
              SizedBox(height: 20),
              
              // Login/Register Button
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        isLogin ? 'Login' : 'Register',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    
              SizedBox(height: 10),
              
              // Toggle between Login and Register
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    errorMessage = null;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}