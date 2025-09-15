class User {
  final String nrm;
  final String nim;
  final String namam;
  final String? tgdaftar;
  final String? tplahir;

  User({
    required this.nrm,
    required this.nim,
    required this.namam,
    this.tgdaftar,
    this.tplahir,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nrm: json['nrm'] ?? '',
      nim: json['nim'] ?? '',
      namam: json['namam'] ?? '',
      tgdaftar: json['tgdaftar'],
      tplahir: json['tplahir'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nrm': nrm,
      'nim': nim,
      'namam': namam,
      'tgdaftar': tgdaftar,
      'tplahir': tplahir,
    };
  }
}
