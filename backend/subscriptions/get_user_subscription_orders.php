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
    $user_id = isset($_GET['user_id']) ? trim($_GET['user_id']) : '';
    if (empty($user_id)) {
        sendError('user_id is required', 400);
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

    $stmt = $conn->prepare("
        SELECT 
            o.id,
            o.user_id,
            o.plan_id,
            o.mess_id,
            o.start_date,
            o.end_date,
            o.total_amount,
            o.selected_items_json,
            o.customer_name,
            o.customer_email,
            o.customer_phone,
            o.status,
            o.created_at,
            p.name as plan_name,
            p.duration_days as plan_duration_days,
            m.name as mess_name,
            m.image_url as mess_image
        FROM subscription_orders o
        LEFT JOIN subscription_plans p ON o.plan_id = p.id
        LEFT JOIN messes m ON o.mess_id = m.id
        WHERE o.user_id = ?
        ORDER BY o.created_at DESC
    ");
    $stmt->bind_param("s", $user_id);
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
