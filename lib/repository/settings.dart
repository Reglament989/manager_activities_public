import 'package:cloud_firestore/cloud_firestore.dart';

final _settingsRef = FirebaseFirestore.instance.collection('settings');

class Blank {
  Blank();
  factory Blank.blank() {
    return Blank();
  }
}

abstract class GetterSnapshots {
  Future getSnapshot() async {}
}

class StatusesSettings implements GetterSnapshots, Blank {
  final String name;
  final int color;
  final ref = _settingsRef
      .doc('statuses')
      .collection('statuses')
      .withConverter<StatusesSettings>(
        fromFirestore: (snapshot, _) =>
            StatusesSettings.fromJson(snapshot.data()!),
        toFirestore: (event, _) => event.toJson(),
      );

  StatusesSettings(this.name, this.color);

  factory StatusesSettings.blank() {
    return StatusesSettings("", 0);
  }

  factory StatusesSettings.fromJson(json) {
    return StatusesSettings(json['name'] as String, json['color'] as int);
  }

  Map<String, dynamic> toJson() => {'name': name, 'color': color};

  @override
  Future<List<StatusesSettings>> getSnapshot() async {
    final List<StatusesSettings> items = [];
    final snapshot = await ref.get();
    List<StatusesSettings> data = snapshot.docs.map((e) => e.data()).toList();
    for (final item in data) {
      items.add(item);
    }
    return items;
  }

  @override
  toString() {
    return name;
  }

  Future add(StatusesSettings s) async {
    await ref.add(s);
  }

  Future delete(StatusesSettings s) async {
    final query = await ref.where("name", isEqualTo: s.name).get();
    for (final i in query.docs) {
      await ref.doc(i.id).delete();
    }
  }
}

class ActivitiesSettings implements GetterSnapshots {
  final String name;
  final ref = _settingsRef
      .doc('activities')
      .collection('activities')
      .withConverter<ActivitiesSettings>(
        fromFirestore: (snapshot, _) =>
            ActivitiesSettings.fromJson(snapshot.data()!),
        toFirestore: (event, _) => event.toJson(),
      );

  ActivitiesSettings(this.name);

  factory ActivitiesSettings.blank() {
    return ActivitiesSettings("");
  }

  factory ActivitiesSettings.fromJson(json) {
    return ActivitiesSettings(json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'name': name};

  @override
  Future<List<String>> getSnapshot() async {
    final List<String> items = [];
    final snapshot = await ref.get();
    List<ActivitiesSettings> data = snapshot.docs.map((e) => e.data()).toList();
    for (final item in data) {
      items.add(item.name);
    }
    return items;
  }

  Future add(ActivitiesSettings s) async {
    await ref.add(s);
  }

  Future delete(String s) async {
    final query = await ref.where("name", isEqualTo: s).get();
    for (final i in query.docs) {
      await ref.doc(i.id).delete();
    }
  }
}
