import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 生成 RSA-2048 密钥对（用于 Discourse user-api-key 授权加密）
class RsaKeyBundle {
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;
  RsaKeyBundle(this.publicKey, this.privateKey);

  /// 公钥 -> PEM (SPKI)，传给 Discourse 的 public_key 参数
  String get publicKeyPem {
    final spki = _encodeSpki(publicKey);
    final b64 = base64.encode(spki);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----\n';
  }

  /// PKCS1v15 解密（Nodeloc 使用的 padding）
  Uint8List decrypt(Uint8List cipherText) {
    final cipher = PKCS1Encoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(cipherText);
  }
}

RsaKeyBundle generateRsaKeyPair() {
  final secureRandom = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = Uint8List.fromList(
      List<int>.generate(32, (_) => seedSource.nextInt(256)));
  secureRandom.seed(KeyParameter(seeds));

  final generator = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64), secureRandom));
  final pair = generator.generateKeyPair();
  return RsaKeyBundle(
    pair.publicKey as RSAPublicKey,
    pair.privateKey as RSAPrivateKey,
  );
}

// ---------------------------------------------------------------- DER 编码

Uint8List _derLen(int len) {
  if (len < 0x80) return Uint8List.fromList([len]);
  final bytes = <int>[];
  var v = len;
  while (v > 0) {
    bytes.insert(0, v & 0xff);
    v >>= 8;
  }
  return Uint8List.fromList([0x80 | bytes.length, ...bytes]);
}

Uint8List _derInt(BigInt v) {
  var bytes = _bigIntBytes(v);
  if (bytes.isEmpty) bytes = Uint8List.fromList([0]);
  if (bytes[0] & 0x80 != 0) {
    bytes = Uint8List.fromList([0x00, ...bytes]);
  }
  return Uint8List.fromList([0x02, ..._derLen(bytes.length), ...bytes]);
}

Uint8List _derSeq(List<Uint8List> parts) {
  final body = BytesBuilder();
  for (final p in parts) {
    body.add(p);
  }
  final content = body.toBytes();
  return Uint8List.fromList([0x30, ..._derLen(content.length), ...content]);
}

/// SubjectPublicKeyInfo: SEQUENCE{ SEQUENCE{OID, NULL}, BIT STRING{ SEQ{ n, e } } }
Uint8List _encodeSpki(RSAPublicKey key) {
  const oid = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
  final alg = Uint8List.fromList([
    0x30, 0x0d, 0x06, 0x09, ...oid, 0x05, 0x00,
  ]);
  final rsaPub = _derSeq([
    _derInt(key.modulus!),
    _derInt(key.exponent!),
  ]);
  final bitString = Uint8List.fromList(
      [0x03, ..._derLen(rsaPub.length + 1), 0x00, ...rsaPub]);
  return _derSeq([alg, bitString]);
}

Uint8List _bigIntBytes(BigInt v) {
  if (v == BigInt.zero) return Uint8List.fromList([0]);
  var n = v;
  final bytes = <int>[];
  while (n > BigInt.zero) {
    bytes.insert(0, (n & BigInt.from(0xff)).toInt());
    n >>= 8;
  }
  return Uint8List.fromList(bytes);
}

// ---------------------------------------------------------------- 授权解析

/// 解析 discourse:// 回调里的 payload：
/// base64 密文 -> RSA PKCS1v15 解密 -> JSON {key, nonce, api, push}
Map<String, dynamic>? decryptUserApiKeyPayload({
  required RsaKeyBundle bundle,
  required String payloadB64,
  required String expectedNonce,
}) {
  try {
    var norm = payloadB64.replaceAll('-', '+').replaceAll('_', '/');
    norm += '=' * (-norm.length % 4);
    final cipher = base64.decode(norm);
    final plain = bundle.decrypt(Uint8List.fromList(cipher));
    final data = jsonDecode(utf8.decode(plain));
    if (data is! Map<String, dynamic>) return null;
    if (data['nonce']?.toString() != expectedNonce) return null;
    return data;
  } catch (_) {
    return null;
  }
}

String randomHex(int length) {
  final r = Random.secure();
  const chars = '0123456789abcdef';
  return List<String>.generate(length, (_) => chars[r.nextInt(16)]).join();
}
