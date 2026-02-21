import 'package:supabase_flutter/supabase_flutter.dart';

class JobService {
  final _supabase = Supabase.instance.client;

  Future<void> aceitarDiaria(String jobId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Usuário não logado");

    // 1. Busca dados atualizados da vaga
    final jobData = await _supabase
        .from('jobs')
        .select('vagas_totais, vagas_ocupadas')
        .eq('id', jobId)
        .single();

    final int totais = jobData['vagas_totais'];
    final int ocupadas = jobData['vagas_ocupadas'];

    // 2. Trava de Segurança: Vaga cheia?
    if (ocupadas >= totais) {
      throw Exception("Poxa, essa vaga acabou de ser preenchida!");
    }

    // 3. Tenta realizar o Check-in
    // Se o usuário já tiver aceito, o banco vai dar erro de 'Unique Constraint'
    // e o bloco catch lá na tela vai pegar.
    await _supabase.from('checkins').insert({
      'trabalhador_id': user.id,
      'job_id': jobId,
      'status': 'confirmado',
      'data_aceite': DateTime.now().toIso8601String(),
    });

    // 4. Atualiza o contador de vagas (Incrementa +1)
    await _supabase
        .from('jobs')
        .update({'vagas_ocupadas': ocupadas + 1})
        .eq('id', jobId);
  }
}