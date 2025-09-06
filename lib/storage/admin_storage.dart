import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/asymmetric/api.dart';
import '../crypto_utils.dart';

class AdminStorage {
  static final AdminStorage _instance = AdminStorage._internal();
  factory AdminStorage() => _instance;
  AdminStorage._internal();

  late File _adminFile;
  late File _privateKeyFile;
  late File _publicKeyFile;

  late RSAPrivateKey _privateKey;
  late RSAPublicKey _publicKey;

  String _adminPassword = 'admin';

  Future<void> init() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/Chordsmith');
    _adminFile = File('${dir.path}/admin.bin');
    _privateKeyFile = File('${dir.path}/private_key.pem');
    _publicKeyFile = File('${dir.path}/public_key.pem');

    if (!await _adminFile.exists() ||
        !await _privateKeyFile.exists() ||
        !await _publicKeyFile.exists()) {
      // First run: generate keys and save
      final keyPair = generateRSAKeyPair();
      if (keyPair.privateKey is RSAPrivateKey) {
        _privateKey = keyPair.privateKey as RSAPrivateKey;
      } else {
        throw Exception('Private key type mismatch');
      }
      if (keyPair.publicKey is RSAPublicKey) {
        _publicKey = keyPair.publicKey as RSAPublicKey;
      } else {
        throw Exception('Public key type mismatch');
      }

      // Save keys to files
      await savePrivateKeyToFile(_privateKeyFile, _privateKey);
      await savePublicKeyToFile(_publicKeyFile, _publicKey);

      // Encrypt and store default admin password
      final encryptedBytes = rsaEncrypt(
        Uint8List.fromList(_adminPassword.codeUnits),
        _publicKey,
      );
      await _adminFile.writeAsBytes(encryptedBytes);
    } else {
      // Load keys from files
      _privateKey = await loadPrivateKeyFromFile(_privateKeyFile);
      _publicKey = await loadPublicKeyFromFile(_publicKeyFile);
    }
  }

  Future<bool> authorizeAdmin(String password) async {
    if (!await _adminFile.exists()) return false;
    final encryptedData = await _adminFile.readAsBytes();
    try {
      final decryptedBytes = rsaDecrypt(encryptedData, _privateKey);
      final decryptedPassword = String.fromCharCodes(decryptedBytes);
      return decryptedPassword == password;
    } catch (_) {
      return false;
    }
  }
}

Future<void> savePrivateKeyToFile(File file, RSAPrivateKey key) async {
}

Future<void> savePublicKeyToFile(File file, RSAPublicKey key) async {
}

Future<RSAPrivateKey> loadPrivateKeyFromFile(File file) async {
  throw UnimplementedError();
}

Future<RSAPublicKey> loadPublicKeyFromFile(File file) async {
  throw UnimplementedError();
}
