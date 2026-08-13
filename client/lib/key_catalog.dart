/// Protocol button IDs shared with Padora Host.
class KeySpec {
  const KeySpec({
    required this.id,
    required this.label,
    this.role,
  });

  final int id;
  final String label;
  final String? role;
}

class KeyCatalog {
  static const up = KeySpec(id: 1, label: '↑');
  static const down = KeySpec(id: 2, label: '↓');
  static const left = KeySpec(id: 3, label: '←');
  static const right = KeySpec(id: 4, label: '→');

  static const z = KeySpec(id: 10, label: 'Z', role: '決定');
  static const x = KeySpec(id: 11, label: 'X', role: '取消');
  static const shift = KeySpec(id: 12, label: 'Shift');
  static const enter = KeySpec(id: 13, label: 'Enter');
  static const space = KeySpec(id: 14, label: 'Space');
  static const esc = KeySpec(id: 15, label: 'Esc');
  static const c = KeySpec(id: 16, label: 'C');
  static const a = KeySpec(id: 17, label: 'A');
  static const s = KeySpec(id: 18, label: 'S');
  static const f4 = KeySpec(id: 20, label: 'F4');
  static const f11 = KeySpec(id: 21, label: 'F11');
  static const f5 = KeySpec(id: 22, label: 'F5');
  static const f8 = KeySpec(id: 23, label: 'F8');
  static const f12 = KeySpec(id: 24, label: 'F12');

  static const assignable = <KeySpec>[
    z,
    x,
    shift,
    enter,
    space,
    esc,
    c,
    a,
    s,
    f4,
    f5,
    f8,
    f11,
    f12,
  ];

  static KeySpec? byId(int? id) {
    if (id == null) {
      return null;
    }
    for (final key in assignable) {
      if (key.id == id) {
        return key;
      }
    }
    return null;
  }
}
