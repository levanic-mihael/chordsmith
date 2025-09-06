import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:crypto/crypto.dart';
import 'package:asn1lib/asn1lib.dart';

String sha256Hash(String input) {
  var bytes = utf8.encode(input);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAKeyPair() {
  final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 12);
  final secureRandom = FortunaRandom();
  var random = Random.secure();
  List<int> seeds = [];
  for (int i = 0; i < 32; i++) {
    seeds.add(random.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
  final rngParams = ParametersWithRandom(keyParams, secureRandom);
  final generator = RSAKeyGenerator();
  generator.init(rngParams);
  return generator.generateKeyPair();
}

BigInt bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

BigInt toBigInt(dynamic number) {
  if (number == null) throw ArgumentError('Key component cannot be null');
  if (number is BigInt) {
    return number;
  } else if (number is Uint8List || number is List<int>) {
    return bytesToBigInt(number as Uint8List);
  } else {
    throw ArgumentError('Unsupported key component type: ${number.runtimeType}');
  }
}

String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  final topLevel = ASN1Sequence();

  topLevel.add(ASN1Integer(toBigInt(publicKey.modulus)));
  topLevel.add(ASN1Integer(toBigInt(publicKey.exponent)));

  final dataBase64 = base64.encode(topLevel.encodedBytes);
  return """-----BEGIN RSA PUBLIC KEY-----\r\n$dataBase64\r\n-----END RSA PUBLIC KEY-----""";
}

String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
  final topLevel = ASN1Sequence();

  topLevel.add(ASN1Integer(BigInt.zero));

  final n = toBigInt(privateKey.n);
  final e = toBigInt(privateKey.exponent);
  final p = toBigInt(privateKey.p);
  final q = toBigInt(privateKey.q);
  final d = toBigInt(privateKey.d);

  topLevel.add(ASN1Integer(n));
  topLevel.add(ASN1Integer(e));
  topLevel.add(ASN1Integer(p));
  topLevel.add(ASN1Integer(q));
  topLevel.add(ASN1Integer(d % (p - BigInt.one)));
  topLevel.add(ASN1Integer(d % (q - BigInt.one)));
  topLevel.add(ASN1Integer(q.modInverse(p)));
  topLevel.add(ASN1Integer(d));

  final dataBase64 = base64.encode(topLevel.encodedBytes);
  return """-----BEGIN RSA PRIVATE KEY-----\r\n$dataBase64\r\n-----END RSA PRIVATE KEY-----""";
}

Uint8List rsaEncrypt(Uint8List dataToEncrypt, RSAPublicKey publicKey) {
  final encryptor = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(Uint8List cipherText, RSAPrivateKey privateKey) {
  final decryptor = PKCS1Encoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return _processInBlocks(decryptor, cipherText);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = (input.length / engine.inputBlockSize).ceil();
  final output = BytesBuilder();
  for (var i = 0; i < numBlocks; i++) {
    final start = i * engine.inputBlockSize;
    final end = start + engine.inputBlockSize;
    final chunk = input.sublist(start, end > input.length ? input.length : end);
    final processed = engine.process(chunk);
    output.add(processed);
  }
  return output.toBytes();
}

Uint8List aesEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
  final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
    ..init(true, PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv), null));
  return cipher.process(data);
}

Uint8List aesDecrypt(Uint8List encrypted, Uint8List key, Uint8List iv) {
  final cipher = PaddedBlockCipher('AES/CBC/PKCS7')
    ..init(false, PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv), null));
  return cipher.process(encrypted);
}
