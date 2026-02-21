import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../app/app_routes.dart';
import 'job_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _availableJobs = [];
  List<String> _myAppliedJobIds = []; // Lista para controlar o que esconder

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ESSA É A FUNÇÃO QUE RESOLVE O SUMIÇO DAS VAGAS ACEITAS
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = _supabase.auth.currentUser;
      
      // 1. Carrega Perfil do Usuário
      if (user != null) {
        _userProfile = await _authService.loadUserProfile(user.id);
        
        // 2. Busca IDs das vagas que o usuário JÁ ACEITOU
        final myApps = await _supabase
            .from('job_applications')
            .select('job_id')
            .eq('worker_id', user.id);
            
        _myAppliedJobIds = List<String>.from(myApps.map((e) => e['job_id'].toString()));
      }

      // 3. Carrega Vagas com status 'aberta'
      final jobsResponse = await _supabase
          .from('jobs')
          .select()
          .eq('status', 'aberta')
          .order('data_diaria', ascending: true);

      if (mounted) {
        final allJobs = List<Map<String, dynamic>>.from(jobsResponse);
        
        setState(() {
          // FILTRO: Só mostra vagas que NÃO estão na lista de aceitas 
          // E que ainda possuem vagas disponíveis
          _availableJobs = allJobs.where((job) {
            final jaAceitei = _myAppliedJobIds.contains(job['id'].toString());
            final ocupadas = job['vagas_ocupadas'] ?? 0;
            final totais = job['vagas_totais'] ?? 1;
            final temVaga = ocupadas < totais;

            return !jaAceitei && temVaga;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PonteLog - Vagas'),
        // Cor do ícone forçada para ser visível
        iconTheme: const IconThemeData(color: Colors.black), 
        actions: [
          // BOTÃO MINHAS DIÁRIAS (Agora com fundo leve para aparecer)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.assignment_turned_in, color: Colors.blue),
              tooltip: 'Minhas Diárias',
              onPressed: () async {
                // Ao voltar da tela de "Minhas Diárias", atualiza a Home
                await Navigator.pushNamed(context, AppRoutes.myJobs);
                _loadInitialData();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vagas Disponíveis (${_availableJobs.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _availableJobs.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _availableJobs.length,
                            itemBuilder: (context, index) {
                              final job = _availableJobs[index];
                              return _buildJobCard(job);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Nenhuma vaga nova para o seu perfil.',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            TextButton(
              onPressed: _loadInitialData,
              child: const Text('Toque para atualizar'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _userProfile?['nome']?[0].toString().toUpperCase() ?? 'U',
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${_userProfile?['nome'] ?? 'Colaborador'}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rank: ${_userProfile?['rank']?.toString().toUpperCase() ?? 'BRONZE'}',
                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          job['titulo'] ?? 'Sem título',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job['local'] ?? 'Extrema-MG'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${job['valor']?.toString() ?? '0.00'}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsPage(job: job),
              ),
            );

            // Se o usuário aceitou a vaga, a tela de detalhes retorna 'true'
            if (result == true) {
              _loadInitialData(); // Atualiza a lista para a vaga sumir
            }
          },
          child: const Text('DETALHES', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}