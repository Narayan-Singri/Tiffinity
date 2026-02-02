<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Log all requests for debugging
$logDir = dirname(__FILE__) . '/logs';
if (!is_dir($logDir)) {
    mkdir($logDir, 0755, true);
}

$logFile = $logDir . '/delete_orders.log';
error_log("=== DELETE REQUEST AT " . date('Y-m-d H:i:s') . " ===\n", 3, $logFile);
error_log("Request Method: " . $_SERVER['REQUEST_METHOD'] . "\n", 3, $logFile);
error_log("Raw Input: " . file_get_contents("php://input") . "\n", 3, $logFile);

// Database connection with fallback
if (file_exists('../config/database.php')) {
    require_once '../config/database.php';
} else {
    // Manual database connection as fallback
    class Database {
        private $host = 'localhost';
        private $db_name = 'tiffin_db';
        private $username = 'root';
        private $password = '';
        private $conn;
        
        public function getConnection() {
            $this->conn = null;
            try {
                $this->conn = new PDO('mysql:host=' . $this->host . ';dbname=' . $this->db_name, $this->username, $this->password);
                $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            } catch(PDOException $e) {
                error_log('Connection Error: ' . $e->getMessage());
            }
            return $this->conn;
        }
    }
}

// Get data from POST form (not JSON)
$order_id = isset($_POST['order_id']) ? intval($_POST['order_id']) : null;
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : null;

error_log("Parsed order_id: " . ($order_id ?? 'NULL') . "\n", 3, $logFile);
error_log("Parsed user_id: " . ($user_id ?? 'NULL') . "\n", 3, $logFile);
error_log("POST data: " . json_encode($_POST) . "\n", 3, $logFile);

if (empty($order_id) || empty($user_id)) {
    error_log("VALIDATION FAILED: Missing order_id or user_id\n", 3, $logFile);
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'order_id and user_id are required',
    ]);
    exit();
}

try {
    error_log("Attempting database connection...\n", 3, $logFile);
    $db = (new Database())->getConnection();
    error_log("Database connection successful\n", 3, $logFile);

    // Verify the order exists and belongs to the user
    error_log("Checking if order exists for user...\n", 3, $logFile);
    $check = $db->prepare("SELECT id, user_id, plan_id FROM subscription_orders WHERE id = ? AND user_id = ?");
    $checkResult = $check->execute([$order_id, $user_id]);
    error_log("Check query executed. Rows found: " . $check->rowCount() . "\n", 3, $logFile);

    if ($check->rowCount() === 0) {
        error_log("Order not found for user_id: $user_id, order_id: $order_id\n", 3, $logFile);
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'Order not found for this user',
        ]);
        exit();
    }

    $orderData = $check->fetch(PDO::FETCH_ASSOC);
    error_log("Found order: " . json_encode($orderData) . "\n", 3, $logFile);

    // Delete the subscription order
    error_log("Executing DELETE query for order_id: $order_id, user_id: $user_id\n", 3, $logFile);
    $stmt = $db->prepare("DELETE FROM subscription_orders WHERE id = ? AND user_id = ?");
    $deleteResult = $stmt->execute([$order_id, $user_id]);
    $rowsDeleted = $stmt->rowCount();
    
    error_log("Delete query executed. Rows deleted: $rowsDeleted\n", 3, $logFile);

    if ($deleteResult && $rowsDeleted > 0) {
        error_log("✅ Order successfully deleted\n", 3, $logFile);
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Subscription order deleted successfully',
            'order_id' => $order_id,
            'rows_deleted' => $rowsDeleted,
        ]);
    } else if ($deleteResult && $rowsDeleted === 0) {
        error_log("⚠️ Delete query executed but no rows were deleted\n", 3, $logFile);
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Order could not be deleted (no matching rows)',
        ]);
    } else {
        error_log("❌ Delete query failed\n", 3, $logFile);
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to delete subscription order',
        ]);
    }
} catch (Exception $e) {
    error_log("❌ EXCEPTION: " . $e->getMessage() . "\n", 3, $logFile);
    error_log("Stack trace: " . $e->getTraceAsString() . "\n", 3, $logFile);
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
    ]);
}


