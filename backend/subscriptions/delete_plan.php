<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
    exit;
}

$plan_id = isset($_POST['plan_id']) ? intval($_POST['plan_id']) : 0;

if ($plan_id <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid plan ID']);
    exit;
}

try {
    // Try to include the database config
    if (file_exists('../config/database.php')) {
        require_once '../config/database.php';
        $database = new Database();
        $db = $database->getConnection();
    } else if (file_exists('../../config/database.php')) {
        require_once '../../config/database.php';
        $database = new Database();
        $db = $database->getConnection();
    } else {
        // Manual database connection as fallback
        $host = 'localhost';
        $db_name = 'tiffin_db';
        $username = 'root';
        $password = '';
        
        try {
            $db = new PDO('mysql:host=' . $host . ';dbname=' . $db_name, $username, $password);
            $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            throw new Exception('Database connection failed: ' . $e->getMessage());
        }
    }
    
    // Check if plan exists
    $check_exists = "SELECT id FROM subscription_plans WHERE id = :plan_id LIMIT 1";
    $stmt = $db->prepare($check_exists);
    $stmt->bindParam(':plan_id', $plan_id, PDO::PARAM_INT);
    $stmt->execute();
    
    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(['status' => 'error', 'message' => 'Plan not found']);
        exit;
    }
    
    // Check if plan has active subscriptions
    $check_query = "SELECT COUNT(*) as count FROM subscriptions 
                    WHERE plan_id = :plan_id AND status IN ('active', 'pending')";
    $check_stmt = $db->prepare($check_query);
    $check_stmt->bindParam(':plan_id', $plan_id, PDO::PARAM_INT);
    $check_stmt->execute();
    $result = $check_stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result && $result['count'] > 0) {
        http_response_code(400);
        echo json_encode([
            'status' => 'error', 
            'message' => 'Cannot delete plan with active subscriptions'
        ]);
        exit;
    }
    
    // Delete the plan
    $delete_query = "DELETE FROM subscription_plans WHERE id = :plan_id";
    $delete_stmt = $db->prepare($delete_query);
    $delete_stmt->bindParam(':plan_id', $plan_id, PDO::PARAM_INT);
    
    if ($delete_stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Plan deleted successfully',
            'plan_id' => $plan_id
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Failed to delete plan'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    error_log('Delete Plan Error: ' . $e->getMessage());
    echo json_encode([
        'status' => 'error',
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>

