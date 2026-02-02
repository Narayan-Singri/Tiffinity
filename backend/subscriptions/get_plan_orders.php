<?php
// Allow cross-origin and JSON responses
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../db.php';

if (!function_exists('sendResponse')) {
    function sendResponse($data, $status = 200)
    {
        http_response_code($status);
        echo json_encode($data);
        exit();
    }
}

if (!function_exists('sendError')) {
    function sendError($message, $status = 400)
    {
        http_response_code($status);
        echo json_encode(['success' => false, 'message' => $message]);
        exit();
    }
}

try {
    $plan_id = isset($_GET['plan_id']) ? intval($_GET['plan_id']) : 0;
    if ($plan_id <= 0) {
        sendError('plan_id is required', 400);
    }

    // Ensure table exists so query does not fail on new environments
    $createTableSql = "CREATE TABLE IF NOT EXISTS subscription_orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        plan_id INT NOT NULL,
        mess_id INT NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        total_amount DECIMAL(10,2) DEFAULT 0,
        selected_items_json LONGTEXT NOT NULL,
        customer_name VARCHAR(255) DEFAULT '',
        customer_email VARCHAR(255) DEFAULT '',
        customer_phone VARCHAR(50) DEFAULT '',
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    $conn->query($createTableSql);

    $stmt = $conn->prepare("SELECT id, user_id, plan_id, mess_id, start_date, end_date, total_amount, selected_items_json, customer_name, customer_email, customer_phone, status, created_at FROM subscription_orders WHERE plan_id = ? ORDER BY created_at DESC");
    $stmt->bind_param("i", $plan_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $items = $row['selected_items_json'];
        $decodedItems = json_decode($items, true);
        $row['selected_items'] = $decodedItems ?: [];
        unset($row['selected_items_json']);
        $orders[] = $row;
    }

    sendResponse(['success' => true, 'data' => $orders]);
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>
