/// Base class for infrastructure-level exceptions.
/// These are caught at repository boundaries and mapped to [Failure] types.
sealed class AuroraException implements Exception {
  const AuroraException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AuroraException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

final class CryptoException extends AuroraException {
  const CryptoException(super.message, {super.cause});
}

final class DatabaseException extends AuroraException {
  const DatabaseException(super.message, {super.cause});
}

final class SyncException extends AuroraException {
  const SyncException(super.message, {super.cause});
}

final class SerializationException extends AuroraException {
  const SerializationException(super.message, {super.cause});
}

final class BackupException extends AuroraException {
  const BackupException(super.message, {super.cause});
}
