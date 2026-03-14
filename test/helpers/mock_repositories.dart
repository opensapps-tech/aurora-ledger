import 'package:aurora_ledger/domain/repositories/expense_repository.dart';
import 'package:aurora_ledger/domain/repositories/group_repository.dart';
import 'package:aurora_ledger/domain/repositories/identity_repository.dart';
import 'package:aurora_ledger/domain/repositories/sync_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockIdentityRepository extends Mock implements IdentityRepository {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockExpenseRepository extends Mock implements ExpenseRepository {}
class MockSyncRepository extends Mock implements SyncRepository {}
