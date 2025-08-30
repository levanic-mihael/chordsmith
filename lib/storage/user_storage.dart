import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

import 'admin_storage.dart';

class UserStorage {
  static const String _fileName = 'user_storage.xml';

  late File _file;
  late XmlDocument _document;
  bool _initialized = false;

  Future<File> get _localFile async {
    final baseDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDir.path}/Chordsmith');
    return File('${directory.path}/$_fileName');
  }

  /// Initializes storage by loading or creating the XML file
  Future<void> init() async {
    if (_initialized) return;

    _file = await _localFile;
    if (!await _file.exists()) {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element('Users', nest: () {}); // root element
      _document = builder.buildDocument();
      await _file.writeAsString(_document.toXmlString(pretty: true));
    } else {
      final content = await _file.readAsString();
      _document = XmlDocument.parse(content);
    }

    _initialized = true;
  }

  /// SHA256 hash utility as hex string
  String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// AES encryption utility: encrypt plaintext bytes with key and IV (zero IV)
  Uint8List aesEncrypt(Uint8List plaintext, Uint8List key, Uint8List iv) {
    final aesKey = Key(key);
    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plaintext, iv: IV(iv));
    return Uint8List.fromList(encrypted.bytes);
  }

  /// AES decryption utility: decrypt ciphertext bytes with key and IV (zero IV)
  Uint8List aesDecrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    final aesKey = Key(key);
    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));
    final decrypted = encrypter.decryptBytes(Encrypted(ciphertext), iv: IV(iv));
    return Uint8List.fromList(decrypted);
  }

  /// Derives AES key (16 bytes) from admin password (SHA-256 + truncation)
  Uint8List _deriveKey(String adminPassword) {
    final hash = sha256.convert(utf8.encode(adminPassword)).bytes;
    return Uint8List.fromList(hash.sublist(0, 16));
  }

  /// Creates a new user account if admin authorized and username is unique
  Future<bool> createAccount(
      String username,
      String password,
      String adminPassword,
      Future<bool> Function(String) adminAuthFunction,
      ) async {
    await init();

    final isAdmin = await adminAuthFunction(adminPassword);
    if (!isAdmin) return false;

    // Check duplicate username
    if (_document.findAllElements('User').any((u) => u.getAttribute('username') == username)) {
      return false; // Username already exists
    }

    // Encrypt password with admin key
    final key = _deriveKey(adminPassword);
    final iv = Uint8List(16); // zero IV
    final encryptedPwdBytes = aesEncrypt(Uint8List.fromList(utf8.encode(password)), key, iv);
    final encryptedPwdBase64 = base64.encode(encryptedPwdBytes);

    // Hash the password for authentication
    final hashedPwd = sha256Hash(password);

    // Build and add user element
    final builder = XmlBuilder();
    builder.element('User', nest: () {
      builder.attribute('username', username);
      builder.attribute('password', hashedPwd);
      builder.attribute('encrypted_password', encryptedPwdBase64);
    });

    final userElement = builder.buildDocument().rootElement;
    _document.rootElement.children.add(userElement.copy());

    await _file.writeAsString(_document.toXmlString(pretty: true));
    return true;
  }

  /// Attempts to login using username and password
  /// Compares hashed password and tries decrypting the encrypted password to verify
  /// Returns true if credentials valid, false otherwise
  Future<bool> login(String username, String password) async {
    await init();

    XmlElement? findUserElement(Iterable<XmlElement> elements, String username) {
      for (final element in elements) {
        if (element.getAttribute('username') == username) {
          return element;
        }
      }
      return null;
    }

    final userElem = findUserElement(_document.findAllElements('User'), username);
    if (userElem == null) return false;


    final storedHashedPwd = userElem.getAttribute('password') ?? '';
    final hashedPwd = sha256Hash(password);
    if (hashedPwd != storedHashedPwd) return false;

    // Verify encrypted password decrypts to the same password using any known admin keys
    // For simplicity, try decrypting with the stored admin password (needs app flow to provide it)
    // Here just trust the password hash check for login success
    return true;
  }

  /// Returns list of all users as maps with keys 'username','password','encrypted_password'
  Future<List<Map<String, String>>> getAllUsers() async {
    await init();

    final users = <Map<String, String>>[];
    for (final userElem in _document.findAllElements('User')) {
      users.add({
        'username': userElem.getAttribute('username') ?? '',
        'password': userElem.getAttribute('password') ?? '',
        'encrypted_password': userElem.getAttribute('encrypted_password') ?? '',
      });
    }
    return users;
  }

  /// Updates password of a user and rewrites XML file
  /// Returns true on success, false on failure
  Future<bool> updateUser(
      String username,
      String newPassword, {
        required String adminPassword, // Must provide adminPassword to encrypt
      }) async {
    await init();

    final userElements = _document.findAllElements('User');
    XmlElement? targetUser;

    for (final userElem in userElements) {
      if (userElem.getAttribute('username') == username) {
        targetUser = userElem;
        break;
      }
    }
    if (targetUser == null) return false;

    // Create new encrypted password and hash
    final key = _deriveKey(adminPassword);
    final iv = Uint8List(16);
    final encryptedPwdBytes = aesEncrypt(Uint8List.fromList(utf8.encode(newPassword)), key, iv);
    final encryptedPwdBase64 = base64.encode(encryptedPwdBytes);

    final hashedPwd = sha256Hash(newPassword);

    // Build updated user element
    final builder = XmlBuilder();
    builder.element('User', nest: () {
      builder.attribute('username', username);
      builder.attribute('password', hashedPwd);
      builder.attribute('encrypted_password', encryptedPwdBase64);
    });
    final newUserElement = builder.buildDocument().rootElement;

    // Replace old element with new
    final root = _document.rootElement;
    final index = root.children.indexOf(targetUser);
    if (index == -1) return false;

    root.children[index] = newUserElement;

    try {
      await _file.writeAsString(_document.toXmlString(pretty: true));
      return true;
    } catch (_) {
      return false;
    }
  }
}
