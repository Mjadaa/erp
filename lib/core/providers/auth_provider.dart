import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class AuthUser {
  final int id;
  final String username;
  final int roleId;
  final String roleName;
  final String permissions;
  final bool mustChangePassword;

  const AuthUser({
    required this.id,
    required this.username,
    required this.roleId,
    required this.roleName,
    required this.permissions,
    required this.mustChangePassword,
  });

  bool get isAdmin => permissions == 'ALL';

  bool hasPermission(String permission) {
    if (permissions == 'ALL') return true;
    return permissions.split(',').map((p) => p.trim()).contains(permission);
  }
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Returns null on success, or a localization key string on failure.
  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'error_fields_required';
    }

    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final hashedPassword = DatabaseHelper.hashPassword(password);

      final result = await db.rawQuery('''
        SELECT u.id, u.username, u.roleId, u.mustChangePassword,
               r.name as roleName, r.permissions
        FROM Users u
        JOIN Roles r ON u.roleId = r.id
        WHERE u.username = ? AND u.password = ? AND u.isActive = 1
        LIMIT 1
      ''', [username.trim(), hashedPassword]);

      if (result.isEmpty) {
        return 'error_invalid_credentials';
      }

      final row = result.first;
      _currentUser = AuthUser(
        id: row['id'] as int,
        username: row['username'] as String,
        roleId: row['roleId'] as int,
        roleName: row['roleName'] as String,
        permissions: row['permissions'] as String,
        mustChangePassword: (row['mustChangePassword'] as int) == 1,
      );

      return null;
    } catch (_) {
      return 'error_login_failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or a localization key string on failure.
  Future<String?> changePassword(String newPassword) async {
    if (_currentUser == null) return 'error_not_logged_in';
    if (newPassword.length < 6) return 'error_password_too_short';

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'Users',
        {
          'password': DatabaseHelper.hashPassword(newPassword),
          'mustChangePassword': 0,
        },
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      _currentUser = AuthUser(
        id: _currentUser!.id,
        username: _currentUser!.username,
        roleId: _currentUser!.roleId,
        roleName: _currentUser!.roleName,
        permissions: _currentUser!.permissions,
        mustChangePassword: false,
      );

      notifyListeners();
      return null;
    } catch (_) {
      return 'error_change_password_failed';
    }
  }

  Future<String?> updateUsername(String newUsername) async {
    if (_currentUser == null) return 'error_not_logged_in';
    final trimmed = newUsername.trim();
    if (trimmed.length < 3) return 'error_username_short';

    try {
      final db = await DatabaseHelper.instance.database;
      final existing = await db.rawQuery(
        'SELECT id FROM Users WHERE username = ? AND id != ?',
        [trimmed, _currentUser!.id],
      );
      if (existing.isNotEmpty) return 'error_username_taken';

      await db.update(
        'Users',
        {'username': trimmed},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      _currentUser = AuthUser(
        id: _currentUser!.id,
        username: trimmed,
        roleId: _currentUser!.roleId,
        roleName: _currentUser!.roleName,
        permissions: _currentUser!.permissions,
        mustChangePassword: _currentUser!.mustChangePassword,
      );
      notifyListeners();
      return null;
    } catch (_) {
      return 'error_change_password_failed';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
