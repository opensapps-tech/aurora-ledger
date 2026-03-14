// TODO: implement using messagepack package
import 'package:aurora_ledger/domain/entities/operation.dart';

class MsgpackSerializer {
  const MsgpackSerializer();

  List<int> serializeOperations(List<Operation> operations) {
    // TODO: implement MessagePack serialisation for operation list
    throw UnimplementedError('MessagePack serialisation not yet implemented');
  }

  List<Operation> deserializeOperations(List<int> bytes) {
    // TODO: implement MessagePack deserialisation
    throw UnimplementedError('MessagePack deserialisation not yet implemented');
  }
}
