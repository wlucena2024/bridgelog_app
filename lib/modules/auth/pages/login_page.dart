import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../app/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();
  final service = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: senha,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                try {
                  await service.login(email.text, senha.text);
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.splash);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao fazer login'),
                    ),
                  );
                }
              },
              child: const Text('Entrar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                    context, AppRoutes.recoverPassword);
              },
              child: const Text('Esqueci minha senha'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
