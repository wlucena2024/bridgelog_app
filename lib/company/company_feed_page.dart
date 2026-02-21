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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Vaga?'),
        content: const Text(
            'Isso removerá a vaga e todos os inscritos nela. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('EXCLUIR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        setState(() => _isLoading = true);

        debugPrint('1. Excluindo candidaturas da vaga: $jobId');
        // Excluir candidaturas
        await _supabase.from('job_applications').delete().eq('job_id', jobId);

        debugPrint('2. Excluindo vaga: $jobId');
        // Excluir vaga
        await _supabase.from('jobs').delete().eq('id', jobId);

        debugPrint('3. Removendo da lista local');
        // Remover da lista local
        if (mounted) {
          setState(() {
            _myJobs.removeWhere((job) => job['id'] == jobId);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaga excluída com sucesso!')),
          );
        }
      } catch (e) {
        debugPrint('❌ ERRO: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir vaga: $e')),
          );
          setState(() => _isLoading = false);
        }
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

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
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
                        final nome = inscrito['nome'] ?? 'Desconhecido';
                        final rank = inscrito['rank'] ?? 'Bronze';
                        final applicationId = inscrito['application_id'];

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                                nome.isNotEmpty ? nome[0].toUpperCase() : '?'),
                          ),
                          title: Text(nome),
                          subtitle: Text('Rank: $rank'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove,
                                color: Colors.red),
                            onPressed: () async {
                              await _supabase
                                  .from('job_applications')
                                  .delete()
                                  .eq('id', applicationId);
                              Navigator.pop(context);
                              _loadCompanyJobs();
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
    debugPrint('🔍 Buscando inscritos para jobId: $jobId');

    try {
      final applications = await _supabase
          .from('job_applications')
          .select('id, worker_id')
          .eq('job_id', jobId);

      debugPrint('📊 Applications: $applications');

      if (applications.isEmpty) return [];

      List<Map<String, dynamic>> inscritos = [];

      for (var app in applications) {
        final workerId = app['worker_id'];
        debugPrint('👤 Buscando users com id: $workerId');

        final userData = await _supabase
            .from('users')
            .select('nome, rank')
            .eq('id', workerId)
            .maybeSingle();

        debugPrint('👤 userData: $userData');

        inscritos.add({
          'application_id': app['id'],
          'nome': userData?['nome'] ?? 'Desconhecido',
          'rank': userData?['rank'] ?? 'Bronze',
        });
      }

      debugPrint('✅ Inscritos: $inscritos');
      return inscritos;
    } catch (e) {
      debugPrint('❌ Erro: $e');
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
