<?php
// Allow cross-origin and JSON responses
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../db.php';

// Fallback helpers in case db.php did not define them
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
    $user_id      = isset($_POST['user_id']) ? trim($_POST['user_id']) : '';
    $plan_id      = isset($_POST['plan_id']) ? intval($_POST['plan_id']) : 0;
    $mess_id      = isset($_POST['mess_id']) ? intval($_POST['mess_id']) : 0;
    $start_date   = isset($_POST['start_date']) ? trim($_POST['start_date']) : '';
    $end_date     = isset($_POST['end_date']) ? trim($_POST['end_date']) : '';
    $total_amount = isset($_POST['total_amount']) ? floatval($_POST['total_amount']) : 0;
    $items_json   = isset($_POST['selected_items']) ? $_POST['selected_items'] : '';
    $customer_name  = isset($_POST['customer_name']) ? trim($_POST['customer_name']) : '';
    $customer_email = isset($_POST['customer_email']) ? trim($_POST['customer_email']) : '';
    $customer_phone = isset($_POST['customer_phone']) ? trim($_POST['customer_phone']) : '';

    if (empty($user_id) || $plan_id <= 0 || $mess_id <= 0 || empty($start_date) || empty($end_date) || empty($items_json)) {
        sendError('Missing required fields (user_id, plan_id, mess_id, start_date, end_date, selected_items)', 400);
    }

    // Ensure table exists
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

    $stmt = $conn->prepare("INSERT INTO subscription_orders (user_id, plan_id, mess_id, start_date, end_date, total_amount, selected_items_json, customer_name, customer_email, customer_phone, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')");
    $stmt->bind_param(
        "siissdssss",
        $user_id,
        $plan_id,
        $mess_id,
        $start_date,
        $end_date,
        $total_amount,
        $items_json,
        $customer_name,
        $customer_email,
        $customer_phone
    );

    if ($stmt->execute()) {
        sendResponse([
            'success' => true,
            'order_id' => $stmt->insert_id,
            'message' => 'Subscription order stored successfully',
        ]);
    } else {
        sendError('Failed to create subscription order: ' . $stmt->error, 500);
    }
} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>
