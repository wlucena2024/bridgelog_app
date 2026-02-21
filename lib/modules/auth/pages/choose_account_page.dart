import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';

class ChooseAccountPage extends StatelessWidget {
  const ChooseAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Começar')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              child: const Text('Criar Conta'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
