import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuko_kadi_iebc_locator/features/home/domain/entities/office.dart';

abstract class OfficesRepository {
  Stream<List<Office>> watchOffices();
}

class FirestoreOfficesRepository implements OfficesRepository {
  FirestoreOfficesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Office>> watchOffices() {
    return _firestore.collection('offices').snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map(_mapDocumentToOffice).toList(growable: false);
    });
  }

  Office _mapDocumentToOffice(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data();

    return Office(
      id: doc.id,
      county: _asString(data['county']),
      constituency: _asString(data['constituency']),
      officeLocation: _asString(data['officeLocation']),
      landmark: _asString(data['landmark']),
      estimatedDistanceText: _optionalString(data['estimatedDistanceText']),
      lat: _asDouble(data['lat']),
      lng: _asDouble(data['lng']),
    );
  }

  String _asString(Object? value) => value is String ? value : '';

  String? _optionalString(Object? value) => value is String ? value : null;

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }
}
