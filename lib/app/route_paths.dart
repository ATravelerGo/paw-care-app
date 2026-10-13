abstract final class AppRoutePaths {
  static const startup = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const health = '/health';
  static const ai = '/ai';
  static const gallery = '/gallery';
  static const profile = '/profile';
  static const conversations = '/ai';
  static const pets = '/pets';
  static const createPet = '/pets/new';
  static const newHealthRecord = '/health/new';

  static String petDetails(String petId) => '/pets/$petId';

  static String editPet(String petId) => '/pets/$petId/edit';

  static String conversationDetails(String conversationId) =>
      '/ai/conversations/$conversationId';

  static String editHealthRecord(String recordId) => '/health/$recordId/edit';

  static String healthRecordDetails(String recordId) => '/health/$recordId';
}
