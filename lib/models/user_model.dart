class UserModel {
  final String id;
  final String nome;
  final String email;
  final String tipo;
  final String telefone;
  final String? cpf;
  final String? cnpj;
  final int pontos;
  final String rank;
  final String fotoPerfilUrl;
  final String? antecedentesUrl;
  final String? curriculoUrl;
  final DateTime dataCriacao;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.telefone,
    this.cpf,
    this.cnpj,
    required this.pontos,
    required this.rank,
    required this.fotoPerfilUrl,
    this.antecedentesUrl,
    this.curriculoUrl,
    required this.dataCriacao,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tipo: map['tipo'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'],
      cnpj: map['cnpj'],
      pontos: map['pontos'] ?? 0,
      rank: map['rank'] ?? 'bronze',
      fotoPerfilUrl: map['foto_perfil_url'] ?? '',
      antecedentesUrl: map['docs'] != null ? map['docs']['antecedentesUrl'] : null,
      curriculoUrl: map['docs'] != null ? map['docs']['curriculoUrl'] : null,
      dataCriacao: map['data_criacao'] != null 
          ? DateTime.parse(map['data_criacao']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'telefone': telefone,
      'cpf': cpf,
      'cnpj': cnpj,
      'pontos': pontos,
      'rank': rank,
      'foto_perfil_url': fotoPerfilUrl,
      'docs': {
        'antecedentesUrl': antecedentesUrl,
        'curriculoUrl': curriculoUrl,
      },
      'data_criacao': dataCriacao.toIso8601String(),
    };
  }
}