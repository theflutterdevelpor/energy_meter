import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();


  Future<void> signUpUser() async {
    setState(() => isLoading = true);

    final url = Uri.parse('http://3.231.62.206:5000/api/v1/admin/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": fullNameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),

          // "phone": phoneController.text.trim(),
        }),
      );

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};


      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Something went wrong'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, String hint,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 15),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2E).withOpacity(0.85),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login1.png',
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF2E2E30),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.greenAccent,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Fill in the details to get started",
                          style:
                          TextStyle(color: Colors.white38, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        TextField(
                          controller: fullNameController,
                          cursorColor: Colors.green,
                          enableInteractiveSelection: false,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                          _inputDecoration("Full Name", "John Doe"),
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: emailController,
                          cursorColor: Colors.green,
                          enableInteractiveSelection: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                              "Email", "johnsondoe@nomail.com"),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),


                        TextField(
                          controller: phoneController,
                          cursorColor: Colors.green,
                          enableInteractiveSelection: false,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                          _inputDecoration("Phone", "03XX-XXXXXXX"),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),


                        TextField(
                          controller: passwordController,
                          cursorColor: Colors.green,
                          enableInteractiveSelection: false,
                          style: const TextStyle(color: Colors.white),
                          obscureText: _obscure,
                          decoration: _inputDecoration(
                            "Password",
                            "Enter your password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextField(
                          controller: confirmPasswordController,
                          cursorColor: Colors.green,
                          enableInteractiveSelection: false,
                          style: const TextStyle(color: Colors.white),
                          obscureText: _obscureConfirm,
                          decoration: _inputDecoration(
                            "Confirm Password",
                            "Re-enter your password",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        ElevatedButton(
                          onPressed: () {
                            if (passwordController.text !=
                                confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Passwords do not match!"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }
                            signUpUser();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.4),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ",
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Log In",
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}