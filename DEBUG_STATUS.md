# Guide de Débogage - Problème d'Affichage du Statut

## Problème Identifié
L'écran d'inactivité ne s'affiche pas malgré le changement de statut.

## Solutions Implémentées

### 1. **Logs de Débogage Ajoutés**
- Logs dans `build()` pour voir le statut actuel
- Logs dans `_checkUserStatus()` pour voir les réponses API
- Logs pour détecter les changements de statut

### 2. **Utilisateur de Test Créé**
- **demo@example.com / demo123** : Statut "Inactif" avec message personnalisé
- **test@example.com / test123** : Statut "Actif" (pour comparaison)

### 3. **API de Test Créée**
- `test_api.php` : Simule les réponses de l'API
- Retourne des données de test pour les utilisateurs 1 et 2

## Étapes de Test

### Étape 1: Vérifier les Logs
1. Lancez l'application
2. Connectez-vous avec `demo@example.com / demo123`
3. Regardez la console pour voir les logs :
   ```
   Statut actuel de l'utilisateur: Inactif
   Message personnalisé: Votre compte a été suspendu...
   Affichage de l'écran d'inactivité
   ```

### Étape 2: Tester l'API
Si vous avez un serveur local, testez l'API :
```bash
curl "http://localhost/test_api.php?id=1"
```

### Étape 3: Vérifier la Configuration
Vérifiez que `lib/config/api_config.dart` pointe vers la bonne URL.

## Diagnostics Possibles

### Si l'écran d'inactivité ne s'affiche toujours pas :

1. **Vérifiez les logs de la console**
   - Le statut affiché est-il "Inactif" ?
   - Y a-t-il des erreurs dans les logs ?

2. **Vérifiez la condition**
   - La condition `_user.status != null && _user.status != 'Actif'` est-elle vraie ?

3. **Testez avec l'utilisateur de test**
   - Connectez-vous avec `test@example.com / test123`
   - L'interface normale s'affiche-t-elle ?

## Solutions Alternatives

### Solution 1: Forcer l'Affichage
Si le problème persiste, modifiez temporairement la condition dans `main_screen.dart` :
```dart
// Remplacer cette ligne :
if (_user.status != null && _user.status != 'Actif') {

// Par cette ligne pour forcer l'affichage :
if (true) { // Force l'affichage pour test
```

### Solution 2: Vérifier le Modèle User
Assurez-vous que les champs `status` et `customMessage` sont bien définis dans le modèle.

### Solution 3: Test Direct
Ajoutez temporairement ce code dans `build()` pour tester :
```dart
// Test direct - à supprimer après test
if (_user.id == '1') {
  return Scaffold(
    body: Center(
      child: Text('Test: Utilisateur 1 détecté - Statut: ${_user.status}'),
    ),
  );
}
```

## Prochaines Étapes

1. **Lancez l'application** et connectez-vous avec `demo@example.com / demo123`
2. **Regardez la console** pour voir les logs
3. **Partagez les logs** si le problème persiste
4. **Testez avec l'utilisateur actif** (`test@example.com / test123`) pour comparaison
