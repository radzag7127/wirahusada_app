import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.namam,
    required super.nrm,
    super.nim,
    super.email,
    super.phone,
    super.tgdaftar,
    super.tplahir,
    super.kdagama,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      namam: json['namam'] ?? '',
      nrm: json['nrm'] ?? '',
      nim: json['nim'],
      email: json['email'],
      phone: json['phone'],
      tgdaftar: json['tgdaftar'],
      tplahir: json['tplahir'],
      kdagama: json['kdagama'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namam': namam,
      'nrm': nrm,
      'nim': nim,
      'email': email,
      'phone': phone,
      'tgdaftar': tgdaftar,
      'tplahir': tplahir,
      'kdagama': kdagama,
    };
  }
}
