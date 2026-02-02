<?php
// Debug logging
error_log("=== get_opt_outs.php called ===", 0);
error_log("REQUEST METHOD: " . $_SERVER['REQUEST_METHOD'], 0);
error_log("GET PARAMS: " . json_encode($_GET), 0);

require_once '../db.php';

// Get opt-outs for a specific plan
$plan_id = isset($_GET['plan_id']) ? intval($_GET['plan_id']) : 0;
error_log("Extracted plan_id: " . $plan_id, 0);

if (!$plan_id) {
    error_log("ERROR: Plan ID is missing", 0);
    sendError('Plan ID is required', 400);
}

try {
    // Query to get opt-outs for a specific plan
    $query = "
        SELECT 
            moo.id,
            moo.subscription_id,
            moo.user_id,
            moo.date,
            moo.meal_time,
            moo.selected_items_json,
            moo.created_at as opted_out_at,
            so.id as order_id,
            so.customer_name as user_name,
            so.customer_email as user_email,
            so.plan_id
        FROM meal_opt_outs moo
        JOIN subscription_orders so ON moo.subscription_id = so.id
        WHERE so.plan_id = ?
        ORDER BY moo.date DESC, moo.created_at DESC
    ";
    
    error_log("Executing query for plan_id: $plan_id", 0);
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        error_log("Prepare error: " . $conn->error, 0);
        sendError("Database error: " . $conn->error, 500);
    }
    
    $stmt->bind_param('i', $plan_id);
    if (!$stmt->execute()) {
        error_log("Execute error: " . $stmt->error, 0);
        sendError("Database error: " . $stmt->error, 500);
    }
    
    $result = $stmt->get_result();
    
    $optOuts = [];
    while ($row = $result->fetch_assoc()) {
        // Get selected items from the meal_opt_outs table
        $selected_items_json = $row['selected_items_json'] ?? '[]';
        $selected_items = json_decode($selected_items_json, true) ?: [];
        
        // Add selected items to the opt-out record
        $row['selected_items'] = $selected_items;
        $optOuts[] = $row;
    }
    
    error_log("Found " . count($optOuts) . " opt-outs for plan_id: $plan_id", 0);
    
    sendResponse($optOuts);
    
} catch (Exception $e) {
    error_log("Error: " . $e->getMessage() . "\n", 3, dirname(__FILE__) . '/logs/get_opt_outs.log');
    sendError('Server error: ' . $e->getMessage(), 500);
}
