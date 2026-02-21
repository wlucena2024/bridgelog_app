import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/storage_service.dart'; // Importe seu StorageService


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  
  // Variáveis para Upload
  File? imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('users').select().eq('id', userId).single();
      
      setState(() {
        _userData = data;
        _nomeController.text = data['nome'] ?? '';
        _telefoneController.text = data['telefone'] ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Lógica de Upload de FOTO
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(image.path);
        final userId = _supabase.auth.currentUser!.id;
        // Caminho: profiles/user_id_timestamp.jpg
        final path = 'profiles/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Usa seu StorageService
        final url = await StorageService.uploadFile(
          bucket: 'documents', // Use o bucket que criamos
          path: path,
          file: file,
        );

        if (url != null) {
          // Atualiza no Banco
          await _supabase.from('users').update({'foto_perfil_url': url}).eq('id', userId);
          await _loadProfile(); // Recarrega tela
          _showSuccess('Foto atualizada!');
        }
      } catch (e) {
        _showError('Erro ao subir foto: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  // Lógica de Upload de DOCUMENTO (PDF)
  Future<void> _pickAndUploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(result.files.single.path!);
        final userId = _supabase.auth.currentUser!.id;
        final ext = result.files.single.extension ?? 'pdf';
        final path = 'antecedentes/${userId}_antecedentes.$ext';

        final url = await StorageService.uploadFile(
          bucket: 'documents',
          path: path,
          file: file,
        );

        if (url != null) {
          // Salva dentro do JSON 'docs' no banco
          final currentDocs = _userData?['docs'] ?? {};
          currentDocs['antecedentesUrl'] = url;
          currentDocs['status_antecedentes'] = 'em_analise'; // Status para o Admin ver

          await _supabase.from('users').update({
            'docs': currentDocs
          }).eq('id', userId);

          await _loadProfile();
          _showSuccess('Documento enviado para análise!');
        }
      } catch (e) {
        _showError('Erro no documento: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _salvarDados() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('users').update({
        'nome': _nomeController.text,
        'telefone': _telefoneController.text,
      }).eq('id', _supabase.auth.currentUser!.id);
      
      _showSuccess('Perfil salvo com sucesso!');
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final docs = _userData?['docs'] ?? {};
    final bool temAntecedentes = docs['antecedentesUrl'] != null;
    final String rank = _userData?['rank'] ?? 'bronze';
    final int pontos = _userData?['pontos'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- CABEÇALHO COM FOTO E RANK ---
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _userData?['foto_perfil_url'] != null
                        ? NetworkImage(_userData!['foto_perfil_url'])
                        : null,
                    child: _userData?['foto_perfil_url'] == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.shade900,
                      radius: 20,
                      child: IconButton(
                        icon: _isUploading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildRankBadge(rank, pontos),
            
            const SizedBox(height: 30),

            // --- SEÇÃO DE DOCUMENTOS (O PULO DO GATO PARA O INVESTIDOR) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: temAntecedentes ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: temAntecedentes ? Colors.green : Colors.orange),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(temAntecedentes ? Icons.verified_user : Icons.warning_amber, 
                           color: temAntecedentes ? Colors.green : Colors.orange),
                      const SizedBox(width: 10),
                      const Text("Segurança e Confiança", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(temAntecedentes 
                    ? "Seus antecedentes criminais estão em análise/aprovados. Você tem prioridade nas vagas!"
                    : "Envie seus Antecedentes Criminais para desbloquear vagas melhores e subir de Rank.",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  if (!temAntecedentes)
                    ElevatedButton.icon(
                      onPressed: _pickAndUploadDocument,
                      icon: const Icon(Icons.upload_file),
                      label: const Text("ENVIAR ANTECEDENTES (PDF/FOTO)"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                    )
                  else
                    TextButton.icon(
                      onPressed: _pickAndUploadDocument, // Permite reenvio se quiser
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Atualizar Documento"),
                    )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- FORMULÁRIO DE DADOS ---
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone / WhatsApp', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField( // Email Read-only
              controller: TextEditingController(text: _userData?['email']),
              decoration: const InputDecoration(labelText: 'E-mail (Não editável)', border: OutlineInputBorder(), filled: true),
              readOnly: true,
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarDados,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String rank, int pontos) {
    Color color;
    switch (rank.toLowerCase()) {
      case 'ouro': color = Colors.amber; break;
      case 'prata': color = Colors.grey; break;
      default: color = Colors.brown.shade300; // Bronze
    }

    return Column(
      children: [
        Chip(
          avatar: Icon(Icons.emoji_events, color: Colors.white),
          label: Text('${rank.toUpperCase()} ($pontos pts)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: color,
        ),
        if (rank.toLowerCase() == 'bronze')
          Text("Faltam ${500 - pontos} pts para Prata", style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}