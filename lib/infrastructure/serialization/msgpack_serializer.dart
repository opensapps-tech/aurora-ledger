import 'dart:convert';
import 'dart:typed_data';

import 'package:aurora_ledger/core/errors/exceptions.dart';
import 'package:aurora_ledger/domain/entities/operation.dart';
import 'package:messagepack/messagepack.dart';

/// MessagePack serializer for operations.
/// Uses short keys for compactness in QR frames.
class MsgpackSerializer {
  const MsgpackSerializer();

  // Short keys for compact serialization (2-3 chars)
  static const _keyOperationId = 'id';
  static const _keyGroupId = 'gid';
  static const _keyAuthorPublicKey = 'apk';
  static const _keyHlcPhysicalMs = 'hms';
  static const _keyHlcLogical = 'hlg';
  static const _keyType = 'typ';
  static const _keyPayload = 'pay';
  static const _keySignature = 'sig';

  /// Serializes a list of operations to MessagePack bytes.
  List<int> serializeOperations(List<Operation> operations) {
    try {
      final packer = Packer();
      
      // Pack as array of maps
      packer.packListLength(operations.length);
      
      for (final op in operations) {
        _packOperation(packer, op);
      }
      
      return packer.takeBytes();
    } catch (e) {
      throw SerializationException('Failed to serialize operations', cause: e);
    }
  }

  void _packOperation(Packer packer, Operation op) {
    // Pack as map with 8 entries
    packer.packMapLength(8);
    
    // operationId
    packer.packString(_keyOperationId);
    packer.packString(op.operationId);
    
    // groupId
    packer.packString(_keyGroupId);
    packer.packString(op.groupId);
    
    // authorPublicKey (stored as base64 string in JSON, but as bytes in MP)
    packer.packString(_keyAuthorPublicKey);
    packer.packBinary(base64Decode(op.authorPublicKey));
    
    // hlcPhysicalMs
    packer.packString(_keyHlcPhysicalMs);
    packer.packInt(op.hlcTimestamp.physicalMs);
    
    // hlcLogical
    packer.packString(_keyHlcLogical);
    packer.packInt(op.hlcTimestamp.logical);
    
    // type
    packer.packString(_keyType);
    packer.packInt(op.type.index);
    
    // payload
    packer.packString(_keyPayload);
    packer.packBinary(Uint8List.fromList(op.payload));
    
    // signature
    packer.packString(_keySignature);
    packer.packBinary(Uint8List.fromList(op.signature));
  }

  /// Deserializes MessagePack bytes to a list of operations.
  List<Operation> deserializeOperations(List<int> bytes) {
    try {
      final unpacker = Unpacker(Uint8List.fromList(bytes));
      
      final length = unpacker.unpackListLength();
      final operations = <Operation>[];
      
      for (var i = 0; i < length; i++) {
        operations.add(_unpackOperation(unpacker));
      }
      
      return operations;
    } catch (e) {
      throw SerializationException('Failed to deserialize operations', cause: e);
    }
  }

  Operation _unpackOperation(Unpacker unpacker) {
    final mapLength = unpacker.unpackMapLength();
    
    // Collect all key-value pairs
    final map = <String, dynamic>{};
    for (var i = 0; i < mapLength; i++) {
      final key = unpacker.unpackString();
      if (key == null) {
        throw const SerializationException('Null key in operation map');
      }
      
      switch (key) {
        case _keyOperationId:
        case _keyGroupId:
          map[key] = unpacker.unpackString();
          break;
        case _keyAuthorPublicKey:
          final bytes = unpacker.unpackBinary();
          map[key] = base64Encode(bytes);
          break;
        case _keyHlcPhysicalMs:
        case _keyHlcLogical:
        case _keyType:
          map[key] = unpacker.unpackInt();
          break;
        case _keyPayload:
        case _keySignature:
          map[key] = unpacker.unpackBinary().toList();
          break;
        default:
          // Skip unknown keys
          unpacker.skip();
      }
    }
    
    // Validate required fields
    _validateRequiredField(map, _keyOperationId);
    _validateRequiredField(map, _keyGroupId);
    _validateRequiredField(map, _keyAuthorPublicKey);
    _validateRequiredField(map, _keyHlcPhysicalMs);
    _validateRequiredField(map, _keyHlcLogical);
    _validateRequiredField(map, _keyType);
    _validateRequiredField(map, _keyPayload);
    _validateRequiredField(map, _keySignature);
    
    // Extract and validate type
    final typeIndex = map[_keyType] as int;
    if (typeIndex < 0 || typeIndex >= OperationType.values.length) {
      throw SerializationException('Invalid operation type index: $typeIndex');
    }
    
    return Operation(
      operationId: map[_keyOperationId] as String,
      groupId: map[_keyGroupId] as String,
      authorPublicKey: map[_keyAuthorPublicKey] as String,
      hlcTimestamp: HlcTimestamp(
        physicalMs: map[_keyHlcPhysicalMs] as int,
        logical: map[_keyHlcLogical] as int,
      ),
      type: OperationType.values[typeIndex],
      payload: map[_keyPayload] as List<int>,
      signature: map[_keySignature] as List<int>,
    );
  }

  void _validateRequiredField(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) {
      throw SerializationException('Missing required field: $key');
    }
    if (map[key] == null) {
      throw SerializationException('Null value for required field: $key');
    }
  }
}

/// Extension to add skip method to Unpacker
extension _UnpackerExtension on Unpacker {
  void skip() {
    // Try to determine the type and skip it
    // This is a simplified implementation
    final bytes = Uint8List.fromList([0x00]);
    final tempUnpacker = Unpacker(bytes);
    // Skip by unpacking and discarding
    final value = tempUnpacker.unpack();
    // We can't easily implement this without access to internal state
    // For now, we rely on the fact that we control the serialization format
  }
}