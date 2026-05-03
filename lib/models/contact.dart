import 'package:hive/hive.dart';

class Contact {
  final String id;
  final String name;
  final String phone;
  final String? email;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });
}

class ContactAdapter extends TypeAdapter<Contact> {
  @override
  final int typeId = 0;

  @override
  Contact read(BinaryReader reader) {
    return Contact(
      id: reader.readString(),
      name: reader.readString(),
      phone: reader.readString(),
      email: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Contact obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.phone);
    if (obj.email != null) {
      writer.writeBool(true);
      writer.writeString(obj.email!);
    } else {
      writer.writeBool(false);
    }
  }
}
