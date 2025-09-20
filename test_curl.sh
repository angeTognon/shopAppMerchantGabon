#!/bin/bash

echo "Test de l'API pour l'utilisateur 1 (statut Inactif):"
curl -s "http://localhost/test_api.php?id=1" | python3 -m json.tool

echo -e "\nTest de l'API pour l'utilisateur 2 (statut Actif):"
curl -s "http://localhost/test_api.php?id=2" | python3 -m json.tool

echo -e "\nTest avec un ID inexistant:"
curl -s "http://localhost/test_api.php?id=999" | python3 -m json.tool
