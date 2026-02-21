import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/app_routes.dart';
import '../../../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Agora usamos apenas o Supabase
  final _supabase = Supabase.instance.client;
  final _service = AuthService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), checkUser);
  }

  Future<void> checkUser() async {
    // Pega o usuário atual do Supabase
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // Busca o perfil no banco de dados (tabela users)
    final data = await _service.loadUserProfile(user.id);
    final tipo = data != null && data['tipo'] != null ? data['tipo'] : 'trabalhador';

    if (!mounted) return;

    if (tipo == 'empresa') {
      Navigator.pushReplacementNamed(context, AppRoutes.companyFeed);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}