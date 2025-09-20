# Surveillance du Statut Utilisateur en Temps Réel

## Fonctionnalité

L'application vérifie automatiquement le statut de l'utilisateur toutes les secondes et change l'interface en conséquence.

## Configuration

### 1. Configuration de l'API

Modifiez le fichier `lib/config/api_config.dart` pour configurer votre URL d'API :

```dart
class ApiConfig {
  static const String baseUrl = 'http://votre-serveur.com';
  static const String getMerchantEndpoint = '/get_merchant.php';
  static const int statusCheckInterval = 1; // Vérification toutes les secondes
}
```

### 2. Structure de la Base de Données

La table `gabon_merchants` doit contenir les colonnes :
- `status` : Statut du marchand ('Actif', 'Inactif', etc.)
- `customMessage` : Message personnalisé affiché à l'utilisateur

## Fonctionnement

### Statut "Actif"
- L'application fonctionne normalement
- L'utilisateur a accès à toutes les fonctionnalités

### Statut différent de "Actif"
- L'écran d'inactivité s'affiche automatiquement
- Message personnalisé (si défini) ou message par défaut
- Bouton de déconnexion disponible

## Test de la Fonctionnalité

### 1. Script de Test

Utilisez le fichier `test_status_change.php` pour tester les changements de statut :

```bash
# Vérifier le statut actuel
curl "http://localhost/test_status_change.php?id=1&action=get"

# Désactiver un compte
curl "http://localhost/test_status_change.php?id=1&action=deactivate&message=Votre compte est suspendu"

# Réactiver un compte
curl "http://localhost/test_status_change.php?id=1&action=activate"
```

### 2. Test dans l'Application

1. Connectez-vous avec un compte de test
2. Utilisez le script de test pour changer le statut
3. Observez le changement automatique d'interface dans l'application

## Gestion des Erreurs

- Les erreurs de réseau n'interrompent pas l'application
- Timeout de 5 secondes pour les requêtes API
- Protection contre les appels simultanés
- Logs des erreurs dans la console

## Performance

- Vérification toutes les secondes (configurable)
- Requêtes HTTP optimisées avec timeout
- Nettoyage automatique des timers
- Mise à jour uniquement en cas de changement de statut

## Sécurité

- Validation des données reçues du serveur
- Gestion sécurisée des erreurs
- Pas d'exposition d'informations sensibles dans les logs
