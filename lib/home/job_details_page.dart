import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Importante para o GPS

class JobDetailsPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  // Estados da Vaga
  bool _jaAceitei = false;
  bool _checkinRealizado = false;
  String? _applicationId;

  @override
  void initState() {
    super.initState();
    _verificarStatusCompleto();
  }

  // Verifica se aceitou E se já fez check-in
  Future<void> _verificarStatusCompleto() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final res = await _supabase
        .from('job_applications')
        .select()
        .eq('job_id', widget.job['id'])
        .eq('worker_id', user.id)
        .maybeSingle();

    if (res != null && mounted) {
      setState(() {
        _jaAceitei = true;
        _applicationId = res['id'];
        // Se o campo checkin_at não for nulo, significa que já fez check-in
        _checkinRealizado = res['checkin_at'] != null;
      });
    }
  }

  // --- LÓGICA DO CHECK-IN COM GPS ---
  Future<void> _realizarCheckIn() async {
    setState(() => _isLoading = true);

    try {
      // 1. Validar se é o dia correto (Regra de Negócio)
      final dataDiaria = DateTime.parse(widget.job['data_diaria']);
      final hoje = DateTime.now();
      
      // Verifica se é o mesmo dia, mês e ano
      final isHoje = dataDiaria.year == hoje.year && 
                     dataDiaria.month == hoje.month && 
                     dataDiaria.day == hoje.day;

      // ATENÇÃO: Para testes hoje, comente o "if" abaixo se a vaga não for para hoje
      if (!isHoje) {
        throw Exception("O Check-in só está liberado no dia da diária (${dataDiaria.day}/${dataDiaria.month}).");
      }

      // 2. Pedir Permissão de GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Precisamos da sua localização para confirmar a presença.");
        }
      }

      // 3. Pegar Posição Atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Salvar no Supabase (Prova de Presença)
      await _supabase.from('job_applications').update({
        'checkin_at': DateTime.now().toIso8601String(),
        'checkin_lat': position.latitude.toString(),
        'checkin_long': position.longitude.toString(),
        'status': 'em_andamento' // Muda status para empresa ver que começou
      }).eq('id', _applicationId!);

      if (!mounted) return;

      setState(() {
        _checkinRealizado = true;
      });

      _mostrarSucesso("Check-in realizado! Bom trabalho.");

    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // ... (Manter suas funções antigas: _confirmarAceite, _cancelarAceite, _mostrarSucesso, _mostrarErro) ...
  // Vou replicar aqui para ficar completo e você só copiar e colar:

  Future<void> _confirmarAceite() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      // Validação Extra: Não deixar aceitar se já tiver outra vaga no mesmo horário (Futuro)
      
      await _supabase.from('job_applications').insert({
        'job_id': widget.job['id'],
        'worker_id': user!.id,
        'status': 'confirmado',
      });

      if (!mounted) return;
      _verificarStatusCompleto(); // Atualiza estado
      _mostrarSucesso('Vaga aceita! Esteja no local no horário combinado.');
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarAceite() async {
    // ... (Mesma lógica anterior) ...
     final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Diária?'),
        content: const Text('Tem certeza? Isso pode afetar seu rank futuro.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NÃO')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SIM', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true && _applicationId != null) {
      setState(() => _isLoading = true);
      try {
        await _supabase.from('job_applications').delete().eq('id', _applicationId!);
        if (!mounted) return;
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Participação cancelada.')));
      } catch (e) {
        _mostrarErro(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarSucesso(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso! 🎉'),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _mostrarErro(String erro) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Erro: ${erro.replaceAll('Exception:', '')}'),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final data = DateTime.parse(job['data_diaria']);
    final dataFormatada = "${data.day}/${data.month} às ${data.hour}h";

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Vaga')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job['titulo'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildStatusBadge(job['status']),
                  const SizedBox(height: 24),
                  _buildValorCard(job['valor'].toString()),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.calendar_today, 'Data', dataFormatada),
                  _buildInfoRow(Icons.location_on, 'Local', job['local'] ?? 'Extrema - MG'),
                  _buildInfoRow(Icons.people, 'Vagas', '${job['vagas_ocupadas'] ?? 0} / ${job['vagas_totais'] ?? 0}'),
                  const Divider(height: 30),
                  
                  // AVISO DE CHECK-IN (Se já aceitou)
                  if (_jaAceitei && !_checkinRealizado)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(child: Text('O botão de Check-in será liberado apenas no dia da diária.', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                    
                   if (_checkinRealizado)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(child: Text('Você já está confirmado no local! Aguarde instruções do gestor.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(job['descricao'] ?? 'Sem descrição.', style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: _buildActionButton(), // Função separada para limpar o build
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTÃO INTELIGENTE ---
  Widget _buildActionButton() {
    // 1. Carregando
    if (_isLoading) {
      return ElevatedButton(
        onPressed: null, 
        child: const CircularProgressIndicator()
      );
    }

    // 2. Check-in Já feito (Sucesso)
    if (_checkinRealizado) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        onPressed: null, // Desabilitado
        icon: const Icon(Icons.check),
        label: const Text('CHECK-IN REALIZADO'),
      );
    }

    // 3. Já aceitou -> Mostra Check-in OU Cancelar
    if (_jaAceitei) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelarAceite,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
              child: const Text('DESISTIR'),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
              onPressed: _realizarCheckIn, // Chama a função com GPS
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text('FAZER CHECK-IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    // 4. Ainda não aceitou -> Botão Aceitar Padrão
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      onPressed: _confirmarAceite,
      child: const Text('ACEITAR DIÁRIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildValorCard(String valor) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          const Text('Valor da Diária', style: TextStyle(color: Colors.grey)),
          Text('R\$ $valor', style: TextStyle(fontSize: 36, color: Colors.blue.shade900, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}