import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web use the built-in GoogleAuthProvider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // user aborted
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await auth.signInWithCredential(credential);
      }
      if (!mounted) return;
  Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Google Sign-In: $e')));
    }
  }

  // For GitHub and Microsoft we provide a web-based OAuth flow; mobile flows require
  // platform setup (OAuth redirect URIs) and are environment-specific. On web we can
  // use Firebase's OAuthProvider directly.
  Future<void> _signInWithOAuthProvider(String providerId) async {
    try {
      if (kIsWeb) {
        final provider = OAuthProvider(providerId);
        await auth.signInWithPopup(provider);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      // On mobile: open external browser for OAuth and capture token with flutter_web_auth.
      // This is a simplified flow and requires correct OAuth app configuration.
      final callbackUrlScheme = 'flutterdoctorauth';
      final authUrl = 'https://example.com/oauth?provider=$providerId&redirect_uri=$callbackUrlScheme://auth';
      final result = await FlutterWebAuth.authenticate(url: authUrl, callbackUrlScheme: callbackUrlScheme);
      // result contains the redirect URL with tokens/params; in a real implementation
      // exchange the code for an access token and create a Firebase credential.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OAuth flow finished: $result')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error OAuth Sign-In: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo / header
              Column(
                children: const [
                  Icon(Icons.medical_services, size: 72, color: Color(0xFF0D47A1)),
                  SizedBox(height: 8),
                  Text('Citas Médicas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  SizedBox(height: 4),
                  Text('Accede a tu cuenta para gestionar tus citas', style: TextStyle(color: Colors.black54)),
                ],
              ),

              const SizedBox(height: 20),

              // Card with form
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Correo Electrónico',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Correo no válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        // Forgot password aligned to end
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.resetPassword);
                            },
                            child: const Text('¿Olvidó su contraseña?'),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Login button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  UserCredential userCredential =
                                      await auth.signInWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Bienvenido ${userCredential.user!.email}")),
                                  );
                                  // Navegar al home/dashboard
                                  Navigator.pushReplacementNamed(context, Routes.home);
                                } on FirebaseAuthException catch (e) {
                                  String message = "";
                                  if (e.code == 'user-not-found') {
                                    message = "Usuario no encontrado";
                                  } else if (e.code == 'wrong-password') {
                                    message = "Contraseña incorrecta";
                                  } else {
                                    message = e.message ?? 'Error';
                                  }
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                            child: const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Create account
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.register);
                            },
                            child: const Text('Crear una cuenta nueva'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Social login header
              SizedBox(
                width: size.width * 0.8,
                child: const Text(
                  'O inicia sesión con',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Social login buttons
              SizedBox(
                width: size.width * 0.8,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.google, color: Color(0xFFDB4437)),
                        label: const Text('Google'),
                        onPressed: _signInWithGoogle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24292E),
                          foregroundColor: Colors.white,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.github),
                        label: const Text('GitHub'),
                        onPressed: () => _signInWithOAuthProvider('github.com'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F2F2F),
                          foregroundColor: Colors.white,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
                        label: const Text('Microsoft'),
                        onPressed: () => _signInWithOAuthProvider('microsoft.com'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Small footer text
              SizedBox(
                width: size.width * 0.8,
                child: const Text(
                  '',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}