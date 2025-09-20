class ApiConfig {
  // URL de base de votre API
  static const String baseUrl = 'https://zoutechhub.com/pharmaRh/gabon';
  
  // Endpoints
  static const String getMerchantEndpoint = '/get_merchant.php';
  
  // Méthode pour construire l'URL complète
  static String getMerchantUrl(String merchantId) {
    return '$baseUrl$getMerchantEndpoint?id=$merchantId';
  }
  
  // Configuration du timeout
  static const Duration requestTimeout = Duration(seconds: 5);
  
  // Intervalle de vérification du statut (en secondes)
  static const int statusCheckInterval = 1;
}
