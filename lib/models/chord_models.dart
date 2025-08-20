class Tonality {
  final int id;
  final String name;
  Tonality({required this.id, required this.name});
}

class Mode {
  final int id;
  final String name;
  Mode({required this.id, required this.name});
}

class ChordType {
  final int id;
  final String name;
  ChordType({required this.id, required this.name});
}

class Chord {
  final int id;
  final int tonalityId;
  final int modeId;
  final int typeId;
  final String tabsFrets;
  final int custom;
  final String displayName;
  Chord({
    required this.id,
    required this.tonalityId,
    required this.modeId,
    required this.typeId,
    required this.tabsFrets,
    this.custom = 0,
    required this.displayName,
  });
}
