import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // LOGIN 100% SUPABASE
  Future<AuthResponse> login(String email, String senha) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: senha,
    );
  }

  // REGISTRO 100% SUPABASE
  Future<AuthResponse> register({
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    required String doc,
  }) async {
    // 1. Cria o usuário no Auth do Supabase
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: senha,
      // Metadados ajudam a identificar o usuário antes mesmo de ler o banco
      data: {'nome': nome, 'tipo': tipo},
    );

    if (res.user == null) throw Exception("Erro ao criar conta.");

    // 2. Insere os dados na tabela 'users'
    // O Supabase usa o ID do Auth automaticamente se configurado
    await _supabase.from('users').insert({
      'id': res.user!.id, 
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'cpf': tipo == 'trabalhador' ? doc : null,
      'cnpj': tipo == 'empresa' ? doc : null,
      'pontos': 0,
      'rank': 'bronze',
      'data_criacao': DateTime.now().toIso8601String(),
    });

    return res;
  }

  // CARREGAR PERFIL
  Future<Map<String, dynamic>?> loadUserProfile(String uid) async {
    return await _supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
  //RESETSENHA
  Future<void> resetPassword(String email) async {
  await _supabase.auth.resetPasswordForEmail(email);
  }
}