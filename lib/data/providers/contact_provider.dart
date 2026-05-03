import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/contact.dart';

class ContactProvider extends ChangeNotifier {
  final Box<Contact> _contactBox;
  final List<Contact> _contacts = [];

  ContactProvider(this._contactBox) {
    _contacts.addAll(_contactBox.values);
  }

  List<Contact> get contacts => List.unmodifiable(_contacts);

  void addContact(Contact contact) {
    _contactBox.put(contact.id, contact);
    _contacts.add(contact);
    notifyListeners();
  }

  void updateContact(Contact updated) {
    _contactBox.put(updated.id, updated);
    final index = _contacts.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _contacts[index] = updated;
      notifyListeners();
    }
  }

  void deleteContact(String id) {
    _contactBox.delete(id);
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Contact? findById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
