import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuko_kadi_iebc_locator/features/home/data/repositories/offices_repository.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final officesRepositoryProvider = Provider<OfficesRepository>((ref) {
  return FirestoreOfficesRepository(ref.watch(firestoreProvider));
});

final officesProvider = StreamProvider<List<Office>>((ref) {
  return ref.watch(officesRepositoryProvider).watchOffices();
});
