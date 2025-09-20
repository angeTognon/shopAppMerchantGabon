<?php
// Script de test simple pour vérifier l'API
header('Content-Type: application/json');

// Simuler des données de marchand pour le test
$testMerchants = [
    '1' => [
        'id' => '1',
        'email' => 'demo@example.com',
        'firstName' => 'Marie',
        'lastName' => 'Dupont',
        'status' => 'Inactif',
        'customMessage' => 'Votre compte a été suspendu pour non-paiement. Veuillez contacter le service client.',
        'points' => 2450,
        'tier' => 'Gold',
        'storeName' => 'Boutique Fashion'
    ],
    '2' => [
        'id' => '2',
        'email' => 'test@example.com',
        'firstName' => 'Test',
        'lastName' => 'User',
        'status' => 'Actif',
        'customMessage' => null,
        'points' => 100,
        'tier' => 'Bronze',
        'storeName' => 'Test Store'
    ]
];

$id = $_GET['id'] ?? null;

if (!$id) {
    echo json_encode(['success' => false, 'error' => 'ID manquant']);
    exit;
}

if (isset($testMerchants[$id])) {
    echo json_encode([
        'success' => true, 
        'merchant' => $testMerchants[$id]
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Marchand non trouvé']);
}
?>
