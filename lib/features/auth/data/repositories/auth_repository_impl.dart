// // auth_repository_impl.dart
// import 'package:sotfbee/features/auth/presentation/pages/login_page.dart';

// class AuthRepositoryImpl implements AuthRepository {
//   final AuthRemoteDataSource remoteDataSource;
//   final AuthLocalDataSource localDataSource;

//   AuthRepositoryImpl({
//     required this.remoteDataSource,
//     required this.localDataSource,
//   });

//   @override
//   Future<UserEntity> login(String email, String password) async {
//     final userModel = await remoteDataSource.login(email, password);
//     await localDataSource.saveToken(userModel.token);
//     return userModel.toEntity();
//   }

//   @override
//   Future<bool> isAuthenticated() async {
//     return await localDataSource.hasToken();
//   }

//   @override
//   Future<void> logout() async {
//     await localDataSource.deleteToken();
//   }

//   @override
//   Future<UserEntity> getCurrentUser() async {
//     final token = await localDataSource.getToken();
//     if (token == null) throw Exception('No authenticated user');
//     final userModel = await remoteDataSource.getCurrentUser(token);
//     return userModel.toEntity();
//   }
// }
