import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
                              Navigator.pushNamed(context, '/reset-password');
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
                                  // Aquí podrías navegar al dashboard de citas
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
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text('Crear una cuenta nueva'),
                          ),
                        ),
                      ],
                    ),
                  ),
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