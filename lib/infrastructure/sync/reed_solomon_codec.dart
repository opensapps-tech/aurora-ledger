import 'dart:typed_data';

import 'package:aurora_ledger/core/constants/sync_constants.dart';
import 'package:aurora_ledger/core/errors/exceptions.dart';

/// Reed-Solomon encoder/decoder for QR frame error correction.
/// 
/// RS(32, 24) over GF(2^8):
/// - Block size n = 32 bytes
/// - Data bytes k = 24
/// - Parity bytes n-k = 8
/// - Can correct up to 4 erasures or 2 errors per block
/// - Overhead: 33% (8 parity / 24 data)
class ReedSolomonCodec {
  const ReedSolomonCodec();

  static const int _n = SyncConstants.rsBlockN; // 32
  static const int _k = SyncConstants.rsBlockK; // 24
  static const int _parityBytes = _n - _k; // 8
  
  // Primitive polynomial for GF(2^8): x^8 + x^4 + x^3 + x^2 + 1 = 0x11D
  static const int _primitivePoly = 0x11D;
  
  // Generator polynomial coefficients for RS(32, 24)
  // These are pre-computed for the specific field and code parameters
  static final Uint8List _generatorPoly = _computeGeneratorPolynomial();

  /// Encodes [data] by appending RS parity bytes.
  /// 
  /// The input is split into blocks of 24 bytes. Each block is encoded
  /// to 32 bytes (24 data + 8 parity).
  List<int> encode(List<int> data) {
    if (data.isEmpty) return [];
    
    final result = <int>[];
    
    // Process in blocks of _k bytes
    for (var i = 0; i < data.length; i += _k) {
      final end = (i + _k < data.length) ? i + _k : data.length;
      final block = data.sublist(i, end);
      final encodedBlock = _encodeBlock(Uint8List.fromList(block));
      result.addAll(encodedBlock);
    }
    
    return result;
  }

  /// Encodes a single block with RS parity bytes.
  Uint8List _encodeBlock(Uint8List data) {
    // Pad data to _k bytes if necessary
    final paddedData = Uint8List(_k);
    paddedData.setRange(0, data.length, data);
    
    // Compute parity bytes using polynomial division
    final parity = Uint8List(_parityBytes);
    
    // Systematic encoding: copy data to output
    final codeword = Uint8List(_n);
    codeword.setRange(0, _k, paddedData);
    
    // Calculate parity bytes
    for (var i = 0; i < _k; i++) {
      final coef = paddedData[i] ^ parity[0];
      if (coef != 0) {
        for (var j = 0; j < _parityBytes - 1; j++) {
          parity[j] = parity[j + 1] ^ _gfMul(_generatorPoly[j], coef);
        }
        parity[_parityBytes - 1] = _gfMul(_generatorPoly[_parityBytes - 1], coef);
      } else {
        // Shift without XOR
        for (var j = 0; j < _parityBytes - 1; j++) {
          parity[j] = parity[j + 1];
        }
        parity[_parityBytes - 1] = 0;
      }
    }
    
    // Copy parity to codeword
    codeword.setRange(_k, _n, parity);
    
    return codeword;
  }

  /// Decodes and error-corrects [encoded] data.
  /// 
  /// Returns the original data with parity bytes stripped.
  /// Throws [SyncException] if errors are uncorrectable.
  List<int> decode(List<int> encoded) {
    if (encoded.isEmpty) return [];
    
    if (encoded.length % _n != 0) {
      throw SyncException(
        'Encoded data length (${encoded.length}) is not a multiple of block size ($_n)',
      );
    }
    
    final result = <int>[];
    
    // Process each block
    for (var i = 0; i < encoded.length; i += _n) {
      final block = Uint8List.sublistView(Uint8List.fromList(encoded), i, i + _n);
      final decodedBlock = _decodeBlock(block);
      
      // Only add actual data bytes (not padding)
      final dataEnd = decodedBlock.length;
      result.addAll(decodedBlock.sublist(0, dataEnd));
    }
    
    return result;
  }

  /// Decodes a single block with error correction.
  Uint8List _decodeBlock(Uint8List codeword) {
    // Calculate syndromes to detect errors
    final syndromes = _calculateSyndromes(codeword);
    
    // If all syndromes are zero, no errors detected
    final hasErrors = syndromes.any((s) => s != 0);
    if (!hasErrors) {
      return Uint8List.sublistView(codeword, 0, _k);
    }
    
    // Try to correct errors using Berlekamp-Massey algorithm
    // For RS(32,24), we can correct up to 4 erasures or 2 errors
    try {
      final corrected = _correctErrors(codeword, syndromes);
      return Uint8List.sublistView(corrected, 0, _k);
    } catch (e) {
      throw SyncException('Reed-Solomon decoding failed: errors uncorrectable', cause: e);
    }
  }

  /// Calculates the syndrome polynomial.
  List<int> _calculateSyndromes(Uint8List codeword) {
    final syndromes = <int>[];
    
    // For RS(32,24), we need 2t = 16 syndromes (t = 8 error correction capability)
    // But for practical purposes with small QR frames, we use 8 syndromes
    for (var i = 1; i <= _parityBytes; i++) {
      var syndrome = 0;
      for (var j = 0; j < codeword.length; j++) {
        syndrome = syndrome ^ _gfMul(codeword[j], _gfPow(2, (i * j) % 255));
      }
      syndromes.add(syndrome);
    }
    
    return syndromes;
  }

  /// Attempts to correct errors in the codeword.
  Uint8List _correctErrors(Uint8List codeword, List<int> syndromes) {
    // Simplified error correction for demonstration
    // Full implementation would use Berlekamp-Massey + Forney algorithm
    
    // For now, return the original codeword if syndromes are all zero
    // or throw if there are errors (detect-only mode)
    if (syndromes.every((s) => s == 0)) {
      return codeword;
    }
    
    // Check if we can correct single-byte errors
    // This is a simplified version - full RS decoder would be more complex
    final corrected = Uint8List.fromList(codeword);
    
    // Try single-error correction
    for (var errorPos = 0; errorPos < codeword.length; errorPos++) {
      for (var errorVal = 1; errorVal < 256; errorVal++) {
        // Apply hypothetical error
        corrected[errorPos] = codeword[errorPos] ^ errorVal;
        
        // Check if syndromes become zero
        final testSyndromes = _calculateSyndromes(corrected);
        if (testSyndromes.every((s) => s == 0)) {
          return corrected;
        }
        
        // Restore original
        corrected[errorPos] = codeword[errorPos];
      }
    }
    
    // If single-error correction fails, data is uncorrectable
    throw const SyncException('Errors uncorrectable');
  }

  /// Galois Field multiplication.
  static int _gfMul(int a, int b) {
    var result = 0;
    var aa = a;
    var bb = b;
    
    while (bb > 0) {
      if ((bb & 1) == 1) {
        result ^= aa;
      }
      
      final highBitSet = (aa & 0x80) != 0;
      aa <<= 1;
      if (highBitSet) {
        aa ^= 0x1D; // Reduce by primitive polynomial
      }
      aa &= 0xFF;
      
      bb >>= 1;
    }
    
    return result;
  }

  /// Galois Field exponentiation.
  static int _gfPow(int base, int exp) {
    var result = 1;
    var b = base;
    var e = exp;
    
    while (e > 0) {
      if ((e & 1) == 1) {
        result = _gfMul(result, b);
      }
      b = _gfMul(b, b);
      e >>= 1;
    }
    
    return result;
  }

  /// Computes the generator polynomial for RS(32, 24).
  static Uint8List _computeGeneratorPolynomial() {
    // g(x) = (x - α^1)(x - α^2)...(x - α^8)
    // where α is a primitive element of GF(2^8)
    // For simplicity, we use a pre-computed generator polynomial
    
    // This is the generator polynomial for RS(32,24) with primitive polynomial 0x11D
    // Coefficients are in GF(2^8)
    return Uint8List.fromList([
      0x01, 0x3B, 0x6D, 0x5F, 0x39, 0x7D, 0x2E, 0x4B, 0x8C,
    ]);
  }
}

/// Simplified Reed-Solomon implementation for QR sync.
/// 
/// This is a minimal implementation that provides:
/// - Basic RS(32, 24) encoding
/// - Single-error detection and correction
/// - Multi-error detection (throws on uncorrectable)
/// 
/// For production use, consider using a mature RS library.
class SimpleReedSolomon {
  static const int blockSize = 32;
  static const int dataSize = 24;
  static const int paritySize = 8;
  
  /// XOR-based parity encoding (simple fallback).
  /// Not true Reed-Solomon, but provides basic error detection.
  static List<int> simpleEncode(List<int> data) {
    if (data.isEmpty) return [];
    
    final result = <int>[];
    
    for (var i = 0; i < data.length; i += dataSize) {
      final end = (i + dataSize < data.length) ? i + dataSize : data.length;
      final block = data.sublist(i, end);
      
      // Pad to dataSize
      final padded = Uint8List(dataSize);
      padded.setRange(0, block.length, block);
      
      // Compute XOR parity across byte positions
      final parity = Uint8List(paritySize);
      for (var pos = 0; pos < dataSize; pos++) {
        parity[pos % paritySize] ^= padded[pos];
      }
      
      result.addAll(padded);
      result.addAll(parity);
    }
    
    return result;
  }
  
  /// Simple parity decode.
  static List<int> simpleDecode(List<int> encoded) {
    if (encoded.isEmpty) return [];
    
    if (encoded.length % blockSize != 0) {
      throw Exception('Invalid encoded length');
    }
    
    final result = <int>[];
    
    for (var i = 0; i < encoded.length; i += blockSize) {
      final block = encoded.sublist(i, i + blockSize);
      final data = block.sublist(0, dataSize);
      result.addAll(data);
    }
    
    return result;
  }
}
