<?php
// ============================================
// TIFFINITY API - DATABASE CONFIGURATION
// AUTO ENVIRONMENT SWITCH (LOCAL / LIVE)
// ============================================

// ---------- CORS HEADERS ----------
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============================================
// ENVIRONMENT DETECTION
// ============================================

$isLocalhost = in_array($_SERVER['HTTP_HOST'], [
    'localhost',
    '127.0.0.1'
]);

// ============================================
// DATABASE CONFIGURATION
// ============================================

if ($isLocalhost) {
    // ✅ LOCAL (XAMPP)
    $servername = "localhost";
    $username   = "root";
    $password   = "";
    $dbname     = "tiffin_db";
} else {
    // ✅ LIVE (HOSTINGER)
    $servername = "localhost";
    $username   = "u820563802_tiffin";
    $password   = "Tiffin@n1234";
    $dbname     = "u820563802_tiffin";
}

// ============================================
// JWT SECRET (same for both)
// ============================================

define('JWT_SECRET', 'tiffinity_secret_2025_CHANGE_THIS_TO_A_RANDOM_STRING');

// ============================================
// CREATE DATABASE CONNECTION
// ============================================

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    die(json_encode([
        "success" => false,
        "message" => "Database connection failed"
    ]));
}

$conn->set_charset("utf8mb4");

// ============================================
// HELPER FUNCTIONS
// ============================================

function sendResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode([
        "success" => true,
        "data" => $data
    ]);
    exit();
}

function sendError($message, $statusCode = 400) {
    http_response_code($statusCode);
    echo json_encode([
        "success" => false,
        "message" => $message
    ]);
    exit();
}

function getJsonInput() {
    return json_decode(file_get_contents("php://input"), true);
}

function validateRequiredFields($data, $fields) {
    foreach ($fields as $field) {
        if (!isset($data[$field]) || trim($data[$field]) === '') {
            return false;
        }
    }
    return true;
}

function sanitizeInput($input) {
    return htmlspecialchars(strip_tags(trim($input)));
}

// ============================================
// JWT FUNCTIONS
// ============================================

function generateJWT($uid, $email) {
    $header = json_encode(["typ" => "JWT", "alg" => "HS256"]);
    $payload = json_encode([
        "uid" => $uid,
        "email" => $email,
        "iat" => time(),
        "exp" => time() + (30 * 24 * 60 * 60)
    ]);

    $h = rtrim(strtr(base64_encode($header), '+/', '-_'), '=');
    $p = rtrim(strtr(base64_encode($payload), '+/', '-_'), '=');
    $s = rtrim(strtr(
        base64_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true)),
        '+/',
        '-_'
    ), '=');

    return "$h.$p.$s";
}

function verifyJWT($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;

    [$h, $p, $s] = $parts;

    $check = rtrim(strtr(
        base64_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true)),
        '+/',
        '-_'
    ), '=');

    if (!hash_equals($check, $s)) return false;

    $payload = json_decode(base64_decode(strtr($p, '-_', '+/')), true);

    if (!$payload || ($payload['exp'] ?? 0) < time()) return false;

    return $payload;
}

function getBearerToken() {
    $headers = getallheaders();
    if (!empty($headers['Authorization']) &&
        preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)
    ) {
        return $matches[1];
    }
    return null;
}

function requireAuth() {
    $token = getBearerToken();
    if (!$token) sendError('Authorization token required', 401);

    $user = verifyJWT($token);
    if (!$user) sendError('Invalid or expired token', 401);

    return $user;
}
?>
