import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:flutter_svg/flutter_svg.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? toggleTheme; // Add toggle theme callback

  const AuthScreen({super.key, this.toggleTheme});

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

  // Fixed Launch URL method
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme to check if dark mode is enabled
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDarkMode
        ? [Colors.deepPurple, Colors.indigo]
        : [Colors.blue, Colors.purple];
        
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLogin ? "Login" : "Register",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
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
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie Animation
                      SizedBox(
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
                                labelStyle: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.never, // Keep label inside
                              ),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
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
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          prefixIcon: Icon(
                            Icons.email,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never, // Keep label inside
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      SizedBox(height: 15),
                      
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          prefixIcon: Icon(
                            Icons.lock,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never, // Keep label inside
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        obscureText: true,
                      ),
                      
                      // Error Message
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: Size(double.infinity, 50),
                                backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                isLogin ? 'Login' : 'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // About Me and attribution fixed at bottom
            Container(
              padding: EdgeInsets.only(bottom: 20, top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "About Me",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LinkedIn Button with actual logo
                      ElevatedButton(
                        onPressed: () {
                          _launchURL('https://www.linkedin.com/in/rian-islam-dev/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(10),
                        ),
                        child: Image.asset(
                          'assets/logos/linkedin_logo.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      // GitHub Button with actual logo
                      ElevatedButton(
                        onPressed: () {
                          _launchURL('https://github.com/Rian445');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(10),
                        ),
                        child: Image.asset(
                          'assets/logos/github_logo.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      // Portfolio Button
                      ElevatedButton(
                        onPressed: () {
                          _launchURL('https://portfolio-rian-islams-projects.vercel.app/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.deepPurple : Colors.blue,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(10),
                        ),
                        child: Icon(Icons.web, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 15), // Gap between buttons and attribution text
                  Text(
                    "A product developed by AORNOB",
                    style: TextStyle(
                      fontSize: 10, // Very small font size
                      color: isDarkMode ? Colors.white54 : Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}