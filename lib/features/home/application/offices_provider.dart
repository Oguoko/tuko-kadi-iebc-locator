import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuko_kadi_iebc_locator/features/home/data/repositories/offices_repository.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ProviderRef<FirebaseFirestore> ref) {
  return FirebaseFirestore.instance;
});

final officesRepositoryProvider = Provider<OfficesRepository>((ProviderRef<OfficesRepository> ref) {
  return FirestoreOfficesRepository(ref.watch(firestoreProvider));
});

final officesProvider = StreamProvider<List<Office>>((Ref ref) {
  return ref.watch(officesRepositoryProvider).watchOffices();
});
