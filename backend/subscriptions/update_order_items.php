<?php
require_once '../db.php';

try {
    $order_id = isset($_POST['order_id']) ? trim($_POST['order_id']) : '';
    $date = isset($_POST['date']) ? trim($_POST['date']) : '';
    $selected_item_ids_str = isset($_POST['selected_item_ids']) ? $_POST['selected_item_ids'] : '[]';

    // Parse IDs
    $selected_item_ids = is_array($selected_item_ids_str) ? $selected_item_ids_str : json_decode($selected_item_ids_str, true);
    $selected_item_ids = is_array($selected_item_ids) ? array_map('intval', $selected_item_ids) : [];

    if (empty($order_id) || empty($date)) {
        sendError('Order ID and date are required.', 400);
    }

    // 1. Fetch current order and subscription details
    $stmt = $conn->prepare("SELECT selected_items_json, user_id, id as subscription_id FROM subscription_orders WHERE id = ?");
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $order = $stmt->get_result()->fetch_assoc();

    if (!$order) {
        sendError("Order not found.", 404);
    }

    $user_id = $order['user_id'];
    $subscription_id = $order['subscription_id'];
    $current_items = json_decode($order['selected_items_json'], true) ?: [];
    
    // 2. Separate items: Keep items from OTHER dates
    $updated_items = array_filter($current_items, function($item) use ($date) {
        return isset($item['date']) && $item['date'] !== $date;
    });

    // 3. Get all available items for this date from menu to identify opted-outs
    $menu_stmt = $conn->prepare("SELECT DISTINCT mi.id FROM menu_subscriptions ms 
        JOIN menu_items mi ON ms.menu_id = mi.menu_id 
        WHERE ms.subscription_id = ? AND DATE(ms.date) = ?");
    $menu_stmt->bind_param("is", $subscription_id, $date);
    $menu_stmt->execute();
    $menu_results = $menu_stmt->get_result();
    
    $available_item_ids = [];
    while ($row = $menu_results->fetch_assoc()) {
        $available_item_ids[] = (int)$row['id'];
    }
    
    // 4. Identify opted-out items (available but not selected)
    $opted_out_ids = array_diff($available_item_ids, $selected_item_ids);
    
    // 5. Record the confirmation when items are selected
    // When user confirms selection, log it in meal_opt_outs table
    // Clear old records for this subscription/date to avoid duplicates
    $delete_stmt = $conn->prepare("DELETE FROM meal_opt_outs WHERE subscription_id = ? AND user_id = ? AND date = ?");
    $delete_stmt->bind_param("iss", $subscription_id, $user_id, $date);
    $delete_stmt->execute();
    
    // 6. Record the confirmed selection in meal_opt_outs table
    // This tracks that the user confirmed their selection for this date
    $insert_stmt = $conn->prepare("INSERT INTO meal_opt_outs (subscription_id, user_id, date, meal_time, created_at) VALUES (?, ?, ?, 'lunch', NOW())");
    $insert_stmt->bind_param("iss", $subscription_id, $user_id, $date);
    if (!$insert_stmt->execute()) {
        error_log("Failed to record selection confirmation: " . $insert_stmt->error);
    }

    // 7. Fetch the actual item details from menu_items table to build the new JSON objects
    $selected_items_details = [];
    if (!empty($selected_item_ids)) {
        $ids_placeholder = implode(',', array_fill(0, count($selected_item_ids), '?'));
        $menu_stmt = $conn->prepare("SELECT id, name, price, type FROM menu_items WHERE id IN ($ids_placeholder)");
        $menu_stmt->bind_param(str_repeat('i', count($selected_item_ids)), ...$selected_item_ids);
        $menu_stmt->execute();
        $menu_results = $menu_stmt->get_result();

        while ($menu_item = $menu_results->fetch_assoc()) {
            $item_detail = [
                "id" => (int)$menu_item['id'],
                "name" => $menu_item['name'],
                "price" => (float)$menu_item['price'],
                "type" => $menu_item['type'],
                "date" => $date,
                "meal_time" => "lunch"
            ];
            $updated_items[] = $item_detail;
            $selected_items_details[] = $item_detail;
        }
    }
    
    // Update meal_opt_outs with selected items details as JSON
    if (!empty($selected_items_details)) {
        $items_json = json_encode($selected_items_details);
        $update_opt_stmt = $conn->prepare("UPDATE meal_opt_outs SET selected_items_json = ? WHERE subscription_id = ? AND user_id = ? AND date = ?");
        $update_opt_stmt->bind_param("siss", $items_json, $subscription_id, $user_id, $date);
        if (!$update_opt_stmt->execute()) {
            error_log("Failed to update selected items: " . $update_opt_stmt->error);
        }
    }

    // 8. Save back to database
    $updated_json = json_encode(array_values($updated_items));
    $upd = $conn->prepare("UPDATE subscription_orders SET selected_items_json = ? WHERE id = ?");
    $upd->bind_param("si", $updated_json, $order_id);
    
    if($upd->execute()) {
        sendResponse([
            'message' => 'Order updated successfully',
            'opted_out_count' => count($opted_out_ids),
            'selected_count' => count($selected_item_ids)
        ]);
    } else {
        sendError('Database update failed', 500);
    }
    
} catch (Exception $e) {
    error_log("Error in update_order_items.php: " . $e->getMessage());
    sendError('System error: ' . $e->getMessage(), 500);
}