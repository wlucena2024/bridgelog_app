import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../app/app_routes.dart';

class CompanyFeedPage extends StatefulWidget {
  const CompanyFeedPage({super.key});

  @override
  State<CompanyFeedPage> createState() => _CompanyFeedPageState();
}

class _CompanyFeedPageState extends State<CompanyFeedPage> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _myJobs = [];

  @override
  void initState() {
    super.initState();
    _loadCompanyJobs();
  }

  Future<void> _loadCompanyJobs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('jobs')
            .select()
            .eq('empresa_id', user.id)
            .order('created_at', ascending: false);
        //setState(() => _myJobs = List<Map<String, dynamic>>.from(response));
        if (mounted) {
          setState(() {
            _myJobs = List<Map<String, dynamic>>.from(response);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erro: $e');
      if (mounted) setState(() => _isLoading = false); //
    } //finally {
    //if (mounted) setState(() => _isLoading = false);
    //}
  }

  Future<void> _excluirVagaCompleta(String jobId) async {
    try {
      // PASSO 1: Verificar checkins
      final checkins = await _supabase
          .from('checkins')
          .select('id, status')
          .eq('job_id', jobId);

      debugPrint('📊 Checkins encontrados: ${checkins.length}');

      // Mensagem personalizada
      String mensagem = 'Isso removerá a vaga e todos os inscritos nela.';
      if (checkins.isNotEmpty) {
        mensagem =
            'ATENÇÃO: Esta vaga tem ${checkins.length} checkin(s) confirmado(s)!\n\n'
            'Ao excluir a vaga, TODOS os checkins serão removidos permanentemente.';
      }

      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir Vaga?'),
          content: Text(mensagem),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('EXCLUIR TUDO',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (confirmar == true) {
        setState(() => _isLoading = true);

        // 🔴 ORDEM CORRETA DE EXCLUSÃO:

        // 1º - Excluir CHECKINS (tabela filha)
        if (checkins.isNotEmpty) {
          debugPrint('1️⃣ Excluindo ${checkins.length} checkins...');
          await _supabase.from('checkins').delete().eq('job_id', jobId);
          debugPrint('   ✅ Checkins excluídos');
        }

        // 2º - Excluir CANDIDATURAS (tabela filha)
        debugPrint('2️⃣ Excluindo candidaturas...');
        await _supabase.from('job_applications').delete().eq('job_id', jobId);

        // 3º - Excluir VAGA (tabela pai)
        debugPrint('3️⃣ Excluindo vaga...');
        await _supabase.from('jobs').delete().eq('id', jobId);

        if (mounted) {
          setState(() {
            _myJobs.removeWhere((job) => job['id'] == jobId);
            _isLoading = false;
          });

          String msg = 'Vaga excluída com sucesso!';
          if (checkins.isNotEmpty) {
            msg = 'Vaga e ${checkins.length} checkin(s) excluídos!';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green),
            const SnackBar(content: Text('Vaga excluída com sucesso!')),
          );
        }
      } catch (e) {
        debugPrint('❌ ERRO: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir vaga: $e')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro detalhado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _verInscritos(String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Colaboradores Confirmados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: _buscarInscritosCompleto(jobId),
                  builder: (context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final inscritos = snapshot.data ?? [];

                    if (inscritos.isEmpty) {
                      return const Center(child: Text('Nenhum inscrito.'));
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: inscritos.length,
                      itemBuilder: (context, index) {
                        final inscrito = inscritos[index];

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(inscrito['nome'][0].toUpperCase()),
                          ),
                          title: Text(inscrito['nome']),
                          subtitle: Text('Rank: ${inscrito['rank']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove,
                                color: Colors.red),
                            onPressed: () async {
                              try {
                                // 1º - Buscar valor atual de vagas_ocupadas
                                final job = await _supabase
                                    .from('jobs')
                                    .select('vagas_ocupadas, vagas_totais')
                                    .eq('id', jobId)
                                    .single();

                                // 2º - Calcular novo valor (nunca abaixo de 0)
                                int novoValor = job['vagas_ocupadas'] - 1;
                                if (novoValor < 0) {
                                  novoValor = 0; // 🔴 IMPEDE VALOR NEGATIVO
                                  debugPrint(
                                      '⚠️ Tentativa de valor negativo - ajustado para 0');
                                }

                                // 3º - Atualizar a vaga com o novo valor
                                await _supabase
                                    .from('jobs')
                                    .update({'vagas_ocupadas': novoValor}).eq(
                                        'id', jobId);

                                // 4º - Excluir a candidatura
                                await _supabase
                                    .from('job_applications')
                                    .delete()
                                    .eq('id', inscrito['application_id']);

                                // 5º - Fechar modal e recarregar
                                Navigator.pop(context);
                                await _loadCompanyJobs();

                                // 6º - Mensagem de sucesso (com aviso se necessário)
                                String mensagem =
                                    'Colaborador removido da vaga';
                                if (job['vagas_ocupadas'] < 0) {
                                  mensagem =
                                      'Colaborador removido (valor negativo corrigido)';
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(mensagem),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint('❌ Erro ao remover colaborador: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao remover: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buscarInscritosCompleto(
      String jobId) async {
    try {
      final applications = await _supabase
          .from('job_applications')
          .select('id, worker_id')
          .eq('job_id', jobId);

      List<Map<String, dynamic>> inscritos = [];

      for (var app in applications) {
        final userData = await _supabase
            .from('users')
            .select('nome, rank')
            .eq('id', app['worker_id'])
            .maybeSingle();

        inscritos.add({
          'application_id': app['id'],
          'nome': userData?['nome'] ?? 'Desconhecido',
          'rank': userData?['rank'] ?? 'Bronze',
        });
      }

      return inscritos;
    } catch (e) {
      debugPrint('Erro ao buscar inscritos: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da Empresa'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _authService.logout().then((_) =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompanyJobs,
              child: _myJobs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _myJobs.length,
                      itemBuilder: (context, index) =>
                          _buildCompanyJobCard(_myJobs[index]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createJob)
            .then((_) => _loadCompanyJobs()),
        label: const Text('Nova Vaga'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade900,
      ),
    );
  }

  Widget _buildCompanyJobCard(Map<String, dynamic> job) {
    final int ocupadas = job['vagas_ocupadas'] ?? 0;
    final int totais = job['vagas_totais'] ?? 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(job['titulo'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('R\$ ${job['valor']} - ${ocupadas}/${totais} Vagas'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                    value: ocupadas / totais,
                    backgroundColor: Colors.grey.shade200),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                        onPressed: () => _verInscritos(job['id']),
                        icon: const Icon(Icons.people),
                        label: const Text('VER INSCRITOS')),
                    IconButton(
                        onPressed: () => _excluirVagaCompleta(job['id']),
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.red)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Nenhuma vaga publicada.'));
  }
}
