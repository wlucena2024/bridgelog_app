import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../app/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AuthService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _docController = TextEditingController(); // Serve para CPF ou CNPJ

  // Variável de controle do Tipo de Conta
  // O padrão é trabalhador, mas muda ao clicar nos botões
  String _tipoConta = 'trabalhador'; 
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _service.register(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        tipo: _tipoConta, // <--- AQUI ESTAVA O POSSÍVEL ERRO (deve passar a variável)
        doc: _docController.text.trim(),
      );

      if (!mounted) return;

      // Sucesso: Redireciona para a tela correta baseada no tipo
      if (_tipoConta == 'empresa') {
        Navigator.pushReplacementNamed(context, AppRoutes.companyFeed);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }

    } catch (e) {
      if (!mounted) return;
      
      String msg = 'Erro ao cadastrar.';
      if (e is AuthException) msg = e.message;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo ao PonteLog',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // SELEÇÃO DE TIPO DE CONTA
              const Text('Eu sou:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Trabalhador')),
                      selected: _tipoConta == 'trabalhador',
                      onSelected: (bool selected) {
                        setState(() {
                          _tipoConta = 'trabalhador';
                          _docController.clear(); // Limpa o campo de documento ao trocar
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Empresa')),
                      selected: _tipoConta == 'empresa',
                      onSelected: (bool selected) {
                        setState(() {
                          _tipoConta = 'empresa';
                          _docController.clear();
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // CAMPOS DO FORMULÁRIO
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: _tipoConta == 'empresa' ? 'Nome da Empresa' : 'Nome Completo',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_tipoConta == 'empresa' ? Icons.business : Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _docController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tipoConta == 'empresa' ? 'CNPJ (somente números)' : 'CPF (somente números)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obrigatório';
                  if (_tipoConta == 'empresa' && value.length < 14) return 'CNPJ inválido';
                  if (_tipoConta == 'trabalhador' && value.length < 11) return 'CPF inválido';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => !value!.contains('@') ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CRIAR CONTA', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}