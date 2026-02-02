<?php
/**
 * Migration: Add selected_items_json column to meal_opt_outs table
 * This column stores the selected items as JSON when a user confirms their selection
 * 
 * Run this migration to update the database schema
 */

require_once '../db.php';

try {
    echo "🔄 Starting migration: Adding selected_items_json to meal_opt_outs...\n";
    
    // Check if column already exists
    $check_column = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
                     WHERE TABLE_NAME = 'meal_opt_outs' 
                     AND COLUMN_NAME = 'selected_items_json'";
    
    $result = $conn->query($check_column);
    
    if ($result && $result->num_rows > 0) {
        echo "✅ Column 'selected_items_json' already exists. No migration needed.\n";
        exit;
    }
    
    // Add the column
    $alter_query = "ALTER TABLE meal_opt_outs ADD COLUMN selected_items_json LONGTEXT DEFAULT NULL AFTER meal_time";
    
    if ($conn->query($alter_query)) {
        echo "✅ Successfully added 'selected_items_json' column to meal_opt_outs table\n";
        echo "📋 Column details:\n";
        echo "   - Type: LONGTEXT\n";
        echo "   - Default: NULL\n";
        echo "   - Position: After meal_time column\n";
        echo "   - Purpose: Stores selected items as JSON (id, name, price, type, date, meal_time)\n";
    } else {
        echo "❌ Error adding column: " . $conn->error . "\n";
        exit(1);
    }
    
} catch (Exception $e) {
    echo "❌ Migration failed: " . $e->getMessage() . "\n";
    exit(1);
}
?>
