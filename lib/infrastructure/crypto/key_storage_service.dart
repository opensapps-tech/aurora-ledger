abstract interface class KeyStorageService {
  Future<void> storeSecretKey(List<int> secretKey);
  Future<List<int>?> loadSecretKey();
  Future<void> storePublicKey(List<int> publicKey);
  Future<List<int>?> loadPublicKey();
  Future<void> storeGroupKey({required String groupId, required List<int> key});
  Future<List<int>?> loadGroupKey({required String groupId});
  Future<void> deleteGroupKey({required String groupId});
  Future<bool> hasIdentityKey();
}
