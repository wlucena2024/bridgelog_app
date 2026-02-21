import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final emailController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool loading = false;
  String? mensagem;
  Color mensagemColor = Colors.green;

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }

  Future<void> _recoverPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() {
        mensagem = 'Digite um email válido.';
        mensagemColor = Colors.red;
      });
      return;
    }

    setState(() {
      loading = true;
      mensagem = null;
    });

    try {
      // Método nativo do Supabase para recuperação de senha
      await _supabase.auth.resetPasswordForEmail(email);

      setState(() {
        mensagem = 'Email de recuperação enviado com sucesso.';
        mensagemColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao enviar email. Tente novamente.';
        mensagemColor = Colors.red;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Informe seu email para receber o link de recuperação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _recoverPassword,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar email'),
            ),
            const SizedBox(height: 20),
            if (mensagem != null)
              Text(
                mensagem!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mensagemColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}