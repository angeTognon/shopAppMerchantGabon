<?php
require 'db.php';
header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
if (!$id) {
    echo json_encode(['success' => false, 'error' => 'ID manquant']);
    exit;
}
$stmt = $pdo->prepare("SELECT * FROM gabon_merchants WHERE id = ?");
$stmt->execute([$id]);
$merchant = $stmt->fetch(PDO::FETCH_ASSOC);
if ($merchant) {
    echo json_encode(['success' => true, 'merchant' => $merchant]);
} else {
    echo json_encode(['success' => false, 'error' => 'Marchand non trouvé']);
}

