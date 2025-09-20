<?php
// Script pour tester l'API réelle
header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
if (!$id) {
    echo json_encode(['success' => false, 'error' => 'ID manquant']);
    exit;
}

// URL de l'API réelle
$apiUrl = "https://zoutechhub.com/pharmaRh/gabon/get_merchant.php?id=$id";

// Faire l'appel à l'API
$response = file_get_contents($apiUrl);

if ($response === false) {
    echo json_encode(['success' => false, 'error' => 'Erreur lors de l\'appel à l\'API']);
    exit;
}

// Retourner la réponse de l'API
echo $response;
?>
