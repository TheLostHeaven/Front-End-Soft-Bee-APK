// import 'package:get_it/get_it.dart';
// import 'package:http/http.dart' as http;
// import 'package:sotfbee/features/inventory/data/datasources/inventory_remote_data_source.dart';
// import 'package:sotfbee/features/inventory/data/repositories/inventory_repository_impl.dart';
// import 'package:sotfbee/features/inventory/domain/repositories/inventory_repository.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/create_inventory_item.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/delete_inventory_item.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/get_inventory_items.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/get_inventory_outputs.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/register_inventory_output.dart';
// import 'package:sotfbee/features/inventory/domain/usecases/update_inventory_item.dart';
// import 'package:sotfbee/features/inventory/presentation/bloc/inventory_bloc.dart';
// import 'package:sotfbee/features/inventory/presentation/bloc/output_bloc.dart';

// final sl = GetIt.instance;

// Future<void> init() async {
//   // BLoC
//   sl.registerFactory(
//     () => InventoryBloc(
//       getInventoryItems: sl(),
//       createInventoryItem: sl(),
//       updateInventoryItem: sl(),
//       deleteInventoryItem: sl(),
//     ),
//   );

//   sl.registerFactory(
//     () => OutputBloc(getInventoryOutputs: sl(), registerInventoryOutput: sl()),
//   );

//   // Use cases
//   sl.registerLazySingleton(() => GetInventoryItems(sl()));
//   sl.registerLazySingleton(() => CreateInventoryItem(sl()));
//   sl.registerLazySingleton(() => UpdateInventoryItem(sl()));
//   sl.registerLazySingleton(() => DeleteInventoryItem(sl()));
//   sl.registerLazySingleton(() => GetInventoryOutputs(sl()));
//   sl.registerLazySingleton(() => RegisterInventoryOutput(sl()));

//   // Repository
//   // sl.registerLazySingleton<InventoryRepository>(
//   //   () => InventoryRepositoryImpl(remoteDataSource: sl()),
//   // );

//   // Data sources
//   sl.registerLazySingleton<InventoryRemoteDataSource>(
//     () => InventoryRemoteDataSource(
//       client: sl(),
//       baseUrl: 'https://softbee-back-end.onrender.com/api', // URL de tu backend
//     ),
//   );

//   // External
//   sl.registerLazySingleton(() => http.Client());
// }
