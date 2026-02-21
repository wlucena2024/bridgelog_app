class JobModel {
  final String id;
  final String titulo;
  final String descricao;
  final String empresaId;
  final String status;
  final int vagasTotais;
  final int vagasOcupadas;
  final double valor;
  final DateTime dataPublicacao;
  final DateTime dataDiaria;
  final String local;

  JobModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.empresaId,
    required this.status,
    required this.vagasTotais,
    required this.vagasOcupadas,
    required this.valor,
    required this.dataPublicacao,
    required this.dataDiaria,
    required this.local,
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      empresaId: map['empresa_id']?.toString() ?? '',
      status: map['status'] ?? 'aberta',
      vagasTotais: map['vagas_totais'] ?? 0,
      vagasOcupadas: map['vagas_ocupadas'] ?? 0,
      valor: (map['valor'] ?? 0).toDouble(),
      dataPublicacao: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      dataDiaria: map['data_diaria'] != null 
          ? DateTime.parse(map['data_diaria']) 
          : DateTime.now(),
      local: map['local'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'empresa_id': empresaId,
      'status': status,
      'vagas_totais': vagasTotais,
      'vagas_ocupadas': vagasOcupadas,
      'valor': valor,
      'data_diaria': dataDiaria.toIso8601String(),
      'local': local,
    };
  }
}