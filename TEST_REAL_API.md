# Test avec l'API Réelle

## Problème Résolu ✅

L'API `get_merchant.php` a été modifiée pour retourner **tous** les marchands (actifs et inactifs) au lieu de filtrer seulement les actifs.

## Changements Effectués

### 1. **API Modifiée** (`get_merchant.php`)
```sql
-- AVANT (ne retournait que les actifs)
SELECT * FROM gabon_merchants WHERE id = ? AND status = 'Actif'

-- APRÈS (retourne tous les marchands)
SELECT * FROM gabon_merchants WHERE id = ?
```

### 2. **Configuration Mise à Jour** (`api_config.dart`)
```dart
static const String baseUrl = 'https://zoutechhub.com/pharmaRh/gabon';
static const String getMerchantEndpoint = '/get_merchant.php';
```

## Comment Tester

### Étape 1: Vérifier l'API
Testez l'API directement dans votre navigateur :
```
https://zoutechhub.com/pharmaRh/gabon/get_merchant.php?id=VOTRE_ID
```

### Étape 2: Modifier le Statut d'un Marchand
Utilisez le script `update_merchant_status.php` pour changer le statut :

```bash
# Désactiver un marchand
curl "https://zoutechhub.com/pharmaRh/gabon/update_merchant_status.php?id=VOTRE_ID&status=Inactif&message=Votre compte est suspendu"

# Réactiver un marchand
curl "https://zoutechhub.com/pharmaRh/gabon/update_merchant_status.php?id=VOTRE_ID&status=Actif"
```

### Étape 3: Tester dans l'Application
1. **Connectez-vous** avec un utilisateur existant
2. **Modifiez le statut** de cet utilisateur via l'API
3. **Observez** le changement automatique dans l'application

## Scripts de Test Créés

### `test_real_api.php`
Teste l'API réelle et retourne la réponse.

### `update_merchant_status.php`
Permet de modifier le statut d'un marchand dans la base de données.

## Exemple de Test Complet

1. **Identifiez un ID de marchand existant** (par exemple : 1, 2, 3...)

2. **Vérifiez le statut actuel** :
   ```
   https://zoutechhub.com/pharmaRh/gabon/get_merchant.php?id=1
   ```

3. **Désactivez le marchand** :
   ```
   https://zoutechhub.com/pharmaRh/gabon/update_merchant_status.php?id=1&status=Inactif&message=Compte suspendu
   ```

4. **Vérifiez que le statut a changé** :
   ```
   https://zoutechhub.com/pharmaRh/gabon/get_merchant.php?id=1
   ```

5. **Testez dans l'application** :
   - Connectez-vous avec ce marchand
   - L'écran d'inactivité devrait s'afficher

## Logs de Débogage

L'application affiche maintenant des logs détaillés dans la console :
- Statut actuel de l'utilisateur
- Réponses de l'API
- Détection des changements de statut

## Résultat Attendu

Maintenant, quand vous modifiez le statut d'un marchand via l'API, l'application devrait automatiquement :
1. Détecter le changement de statut
2. Afficher l'écran d'inactivité si le statut n'est pas "Actif"
3. Afficher l'interface normale si le statut est "Actif"
