class CheckinModel {
  final String id;
  final String trabalhadorId;
  final String jobId;
  final DateTime dataAceite;
  final String status;

  CheckinModel({
    required this.id,
    required this.trabalhadorId,
    required this.jobId,
    required this.dataAceite,
    required this.status,
  });

  factory CheckinModel.fromMap(Map<String, dynamic> map) {
    return CheckinModel(
      id: map['id']?.toString() ?? '',
      trabalhadorId: map['trabalhador_id']?.toString() ?? '',
      jobId: map['job_id']?.toString() ?? '',
      dataAceite: map['data_aceite'] != null 
          ? DateTime.parse(map['data_aceite']) 
          : DateTime.now(),
      status: map['status'] ?? 'pendente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trabalhador_id': trabalhadorId,
      'job_id': jobId,
      'data_aceite': dataAceite.toIso8601String(),
      'status': status,
    };
  }
}