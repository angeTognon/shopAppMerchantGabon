<?php
require 'db.php';
header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
$status = $_GET['status'] ?? null;
$message = $_GET['message'] ?? null;

if (!$id || !$status) {
    echo json_encode(['success' => false, 'error' => 'ID et statut requis']);
    exit;
}

try {
    if ($message) {
        $stmt = $pdo->prepare("UPDATE gabon_merchants SET status = ?, customMessage = ? WHERE id = ?");
        $stmt->execute([$status, $message, $id]);
    } else {
        $stmt = $pdo->prepare("UPDATE gabon_merchants SET status = ?, customMessage = NULL WHERE id = ?");
        $stmt->execute([$status, $id]);
    }
    
    echo json_encode([
        'success' => true, 
        'message' => "Statut mis à jour vers '$status'",
        'affected_rows' => $stmt->rowCount()
    ]);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
