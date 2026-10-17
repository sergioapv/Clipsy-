import 'dart:async';

import 'package:clipsy/features/auth/data/auth_repository.dart';
import 'package:clipsy/features/auth/domain/app_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this._user});

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();
  final sentLinks = <String>[];

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  void emit(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> sendMagicLink(String email) async => sentLinks.add(email);

  @override
  Future<void> signInWithGoogle() async =>
      emit(const AppUser(id: 'google-user', email: 'parent@example.com'));

  @override
  Future<void> signOut() async => emit(null);
}
