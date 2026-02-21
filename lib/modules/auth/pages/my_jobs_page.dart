import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ADICIONE ESTE IMPORT ABAIXO (Verifique se o caminho está correto conforme seu projeto)
import '/home/job_details_page.dart'; 

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _myAcceptedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  Future<void> _loadMyJobs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('job_applications')
          .select('*, jobs(*)')
          .eq('worker_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myAcceptedJobs = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar diárias: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Diárias')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMyJobs,
              child: _myAcceptedJobs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _myAcceptedJobs.length,
                      itemBuilder: (context, index) {
                        final application = _myAcceptedJobs[index];
                        final job = application['jobs'];
                        
                        // Proteção caso a vaga tenha sido excluída
                        if (job == null) return const SizedBox.shrink();
                        
                        return _buildJobCard(job);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Usando ListView para o RefreshIndicator funcionar no estado vazio
      children: const [
        SizedBox(height: 100),
        Center(child: Text('Você ainda não aceitou nenhuma diária.')),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.work, color: Colors.blue),
        ),
        title: Text(
          job['titulo'] ?? 'Sem título', 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        subtitle: Text('Local: ${job['local'] ?? 'Extrema - MG'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),

        onTap: () async {
          // O 'await' espera a tela de detalhes fechar
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailsPage(job: job)),
          );

          //Se voltou com 'true', significa que houve mudança (desistiu ou checkin)
          if (result == true){
            _loadMyJobs(); //Recarrega a lista para assumir a vaga destinada
          }
        },
      ),
    );
  }
}