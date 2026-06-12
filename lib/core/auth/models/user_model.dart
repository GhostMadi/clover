import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  factory UserModel.fromSupabaseUser(supabase.User user) {
    final metadata = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      name: _readName(metadata),
      avatarUrl: _readAvatar(metadata),
    );
  }

  static String _readName(Map<String, dynamic> metadata) {
    final fullName = metadata['full_name'];
    if (fullName is String && fullName.isNotEmpty) return fullName;

    final name = metadata['name'];
    if (name is String && name.isNotEmpty) return name;

    return '';
  }

  static String? _readAvatar(Map<String, dynamic> metadata) {
    final avatarUrl = metadata['avatar_url'];
    if (avatarUrl is String && avatarUrl.isNotEmpty) return avatarUrl;

    final picture = metadata['picture'];
    if (picture is String && picture.isNotEmpty) return picture;

    return null;
  }
}
