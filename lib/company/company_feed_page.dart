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
        setState(() => _myJobs = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirVagaCompleta(String jobId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Vaga?'),
        content: const Text('Isso removerá a vaga e todos os inscritos nela. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('EXCLUIR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
      //BUG-001(FIXED)- ERRO AO EXCLUIR A VAGA NO MODAL EMPRESA 21*02*2026
      //Realiza a exclusão dos aplicantes antes de excluir a vaga - wLucena

      setState(() => _isLoading = true); // Mostra loading enquanto exclui

      await _supabase.from('job_applications')
                     .delete()
                     .eq('id', jobId);
      //Realiza a exclusão da vaga - wLucena 
      await _supabase.from('jobs')
                     .delete()
                     .eq('id', jobId);

      await _loadCompanyJobs();
      
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga excluída com sucesso!')),
        );
        };
        
      } catch (e) {
        debugPrint('Erro ao excluir: $e');
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir vaga: $e')),
        );
        }
        setState(() => _isLoading = false);
      }
       
    }
  }

  void _verInscritos(String jobId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Colaboradores Confirmados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  // O .select('..., users(*)') é o que resolve o "Desconhecido"
                  future: _supabase.from('job_applications').select('id, users(*)').eq('job_id', jobId),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final data = snapshot.data as List;
                    if (data.isEmpty) return const Center(child: Text('Nenhum inscrito.'));

                    return ListView.builder(
                      controller: controller,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final application = data[index];
                        final worker = application['users'];
                        final nome = worker?['nome'] ?? 'Desconhecido';

                        return ListTile(
                          leading: CircleAvatar(child: Text(nome[0].toUpperCase())),
                          title: Text(nome),
                          subtitle: Text('Rank: ${worker?['rank'] ?? 'Bronze'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.red),
                            onPressed: () async {
                              await _supabase.from('job_applications').delete().eq('id', application['id']);
                              Navigator.pop(context); // Fecha modal
                              _loadCompanyJobs(); // Atualiza contador 0/x
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da Empresa'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _authService.logout().then((_) => Navigator.pushReplacementNamed(context, AppRoutes.login))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCompanyJobs,
              child: _myJobs.isEmpty ? _buildEmptyState() : ListView.builder(
                itemCount: _myJobs.length,
                itemBuilder: (context, index) => _buildCompanyJobCard(_myJobs[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createJob).then((_) => _loadCompanyJobs()),
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
        title: Text(job['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('R\$ ${job['valor']} - ${ocupadas}/${totais} Vagas'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: ocupadas / totais, backgroundColor: Colors.grey.shade200),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(onPressed: () => _verInscritos(job['id']), icon: const Icon(Icons.people), label: const Text('VER INSCRITOS')),
                    IconButton(onPressed: () => _excluirVagaCompleta(job['id']), icon: const Icon(Icons.delete_forever, color: Colors.red)),
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