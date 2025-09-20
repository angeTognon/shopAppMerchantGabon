<?php
// Script de test pour simuler un changement de statut
// Ce fichier peut être utilisé pour tester le changement automatique d'interface

require 'db.php';
header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
$action = $_GET['action'] ?? 'get';

if (!$id) {
    echo json_encode(['success' => false, 'error' => 'ID manquant']);
    exit;
}

switch ($action) {
    case 'get':
        // Récupérer le statut actuel
        $stmt = $pdo->prepare("SELECT status, customMessage FROM gabon_merchants WHERE id = ?");
        $stmt->execute([$id]);
        $merchant = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($merchant) {
            echo json_encode([
                'success' => true, 
                'status' => $merchant['status'],
                'customMessage' => $merchant['customMessage']
            ]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Marchand non trouvé']);
        }
        break;
        
    case 'activate':
        // Activer le compte
        $stmt = $pdo->prepare("UPDATE gabon_merchants SET status = 'Actif', customMessage = NULL WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'message' => 'Compte activé']);
        break;
        
    case 'deactivate':
        // Désactiver le compte
        $message = $_GET['message'] ?? 'Votre compte a été temporairement suspendu.';
        $stmt = $pdo->prepare("UPDATE gabon_merchants SET status = 'Inactif', customMessage = ? WHERE id = ?");
        $stmt->execute([$message, $id]);
        echo json_encode(['success' => true, 'message' => 'Compte désactivé']);
        break;
        
    default:
        echo json_encode(['success' => false, 'error' => 'Action non reconnue']);
}
?>
