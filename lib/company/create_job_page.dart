import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _vagasController = TextEditingController();
  final _localController = TextEditingController(text: 'Extrema - MG');
  
  DateTime _dataSelecionada = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  Future<void> _salvarVaga() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('jobs').insert({
        'empresa_id': user.id,
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'valor': double.parse(_valorController.text.replaceAll(',', '.')),
        'vagas_totais': int.parse(_vagasController.text),
        'vagas_ocupadas': 0,
        'status': 'aberta',
        'local': _localController.text,
        'data_diaria': _dataSelecionada.toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context); // Volta para o feed atualizando
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaga publicada com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao publicar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Diária')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(labelText: 'Título da Vaga (Ex: Carga e Descarga)'),
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(labelText: 'Descrição do Serviço'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _valorController,
                          decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _vagasController,
                          decoration: const InputDecoration(labelText: 'Qtd Vagas'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _localController,
                    decoration: const InputDecoration(labelText: 'Localização'),
                  ),
                  const SizedBox(height: 25),
                  ListTile(
                    title: const Text("Data e HOra da Diária"),
                    subtitle: Text("${_dataSelecionada.day}/${_dataSelecionada.month} às ${_dataSelecionada.hour}:${_dataSelecionada.minute.toString().padLeft(2, '0')}h"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      //Escolher Data carai
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dataSelecionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                       
                      if (date == null)  return; //Cancelou
                      if (!mounted) return;
                      //Escolher a merda da hora
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_dataSelecionada),
                      );
                      if (time == null) return; // Cancelou

                      //3. Juntar Data + Hora
                      setState((){
                        _dataSelecionada = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute 
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _salvarVaga,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text('PUBLICAR VAGA'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}