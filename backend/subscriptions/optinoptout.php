<?php
// Headers to allow cross-origin and specify response format
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
// Allow the client to tell us they are sending form data
header('Access-Control-Allow-Headers: Content-Type'); 
header('Content-Type: application/json');

// Handle Preflight Request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../db.php';

try {
    // $_POST automatically reads 'application/x-www-form-urlencoded' data
    $subscription_id = isset($_POST['subscription_id']) ? intval($_POST['subscription_id']) : 0;
    $user_id         = isset($_POST['user_id']) ? trim($_POST['user_id']) : '';
    $date            = isset($_POST['date']) ? trim($_POST['date']) : '';
    $meal_time       = isset($_POST['meal_time']) ? trim($_POST['meal_time']) : '';
    $action          = isset($_POST['action']) ? trim($_POST['action']) : ''; // 'opt_in' or 'opt_out'

    // 1. Validation
    if ($subscription_id <= 0 || empty($user_id) || empty($date) || empty($meal_time) || empty($action)) {
        sendError('All fields are required (subscription_id, user_id, date, meal_time, action)', 400);
    }

    if (!in_array($action, ['opt_in', 'opt_out'])) {
        sendError('Invalid action. Must be opt_in or opt_out', 400);
    }

    // 2. Verify Subscription
    $stmt = $conn->prepare("SELECT id FROM user_subscriptions WHERE id = ? AND user_id = ? AND status = 'active'");
    $stmt->bind_param("is", $subscription_id, $user_id);
    $stmt->execute();

    if ($stmt->get_result()->num_rows === 0) {
        sendError('Subscription not found or inactive', 404);
    }

    // 3. Logic: Opt-Out (Insert) or Opt-In (Delete)
    if ($action === 'opt_out') {
        // User wants to SKIP
        $stmt = $conn->prepare("
            INSERT INTO meal_opt_outs (subscription_id, user_id, date, meal_time, created_at)
            VALUES (?, ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE created_at = NOW()
        ");
        $stmt->bind_param("isss", $subscription_id, $user_id, $date, $meal_time);

        if ($stmt->execute()) {
            sendResponse(['success' => true, 'status' => 'skipped', 'message' => 'Meal skipped'], 200);
        } else {
            throw new Exception($stmt->error);
        }

    } else {
        // User wants to INCLUDE (Undo skip)
        $stmt = $conn->prepare("DELETE FROM meal_opt_outs WHERE subscription_id = ? AND user_id = ? AND date = ? AND meal_time = ?");
        $stmt->bind_param("isss", $subscription_id, $user_id, $date, $meal_time);

        if ($stmt->execute()) {
            sendResponse(['success' => true, 'status' => 'active', 'message' => 'Meal active'], 200);
        } else {
            throw new Exception($stmt->error);
        }
    }

} catch (Exception $e) {
    sendError('Server error: ' . $e->getMessage(), 500);
}
?>