abstract interface class IAdminRequestRepository {
  Future<void> requestToAdmin(String token, String request);
}
