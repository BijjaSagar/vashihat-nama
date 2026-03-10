<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

define('SECURE_ACCESS', true);

session_start();
require_once 'includes/config.php';
require_once 'includes/function.php';

header('Content-Type: application/json');

if (!function_exists('sanitize_input')) {
    function sanitize_input($data)
    {
        return htmlspecialchars(stripslashes(trim($data)));
    }
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get JSON input because Flutter sends application/json
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);

    // Fallback to $_POST form-data if JSON is empty
    if (!empty($data)) {
        $_POST = array_merge($_POST, $data);
    }

    try {
        $mobile = sanitize_input($_POST["mobile"] ?? $_POST["phone"] ?? '');
        $entered_otp = sanitize_input($_POST["otp"] ?? '');

        // Clean inputs
        $mobile = preg_replace('/[^0-9]/', '', $mobile);
        $entered_otp = preg_replace('/[^0-9]/', '', $entered_otp);

        // Validate
        if (strlen($mobile) != 10 || strlen($entered_otp) != 6) {
            throw new Exception('Invalid mobile number or OTP format');
        }

        //error_log("Verifying - Mobile: $mobile, OTP: $entered_otp");

        // Get OTP record - NO EXPIRY CHECK FOR TESTING AS REQUESTED
        $stmt = $conn->prepare("SELECT id, otp, attempts, expires_at, created_at FROM otp_verifications WHERE mobile = ? AND is_used = 0 ORDER BY created_at DESC LIMIT 1");
        $stmt->bind_param("s", $mobile);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $otp_record = $result->fetch_assoc();

            // Check attempts
            if ($otp_record['attempts'] >= 3) {
                $conn->query("DELETE FROM otp_verifications WHERE id = " . $otp_record['id']);
                throw new Exception('Maximum attempts exceeded. Please request a new OTP.');
            }

            // Verify OTP
            if ($entered_otp == $otp_record['otp']) {
                // Mark as used
                $conn->query("UPDATE otp_verifications SET is_used = 1 WHERE id = " . $otp_record['id']);

                // Get user
                $user_stmt = $conn->prepare("SELECT * FROM users WHERE mobile = ?");
                $user_stmt->bind_param("s", $mobile);
                $user_stmt->execute();
                $user_result = $user_stmt->get_result();

                if ($user_result->num_rows == 0) {
                    throw new Exception('User not found');
                }

                $user = $user_result->fetch_assoc();

                // Set session
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['user_name'] = $user['name'];
                $_SESSION['user_mobile'] = $user['mobile'];
                $_SESSION['user_role'] = $user['role'] ?? 'public';
                $_SESSION['user_village'] = $user['village'] ?? '';
                $_SESSION['login_time'] = time();

                // Clear OTP session
                unset($_SESSION['login_otp'], $_SESSION['login_mobile'], $_SESSION['otp_time'], $_SESSION['otp_attempts']);

                // Generate token for app
                $token = bin2hex(random_bytes(32)); // Create a token for mobile app if not using sessions

                echo json_encode([
                    'success' => true,
                    'message' => 'Login successful',
                    'token' => $token, // Return token for app
                    'user' => [
                        'id' => $user['id'],
                        'name' => $user['name'],
                        'mobile' => $user['mobile'],
                        'role' => $user['role'] ?? 'public'
                    ]
                ]);

            } else {
                // Wrong OTP
                $new_attempts = $otp_record['attempts'] + 1;
                $conn->query("UPDATE otp_verifications SET attempts = $new_attempts WHERE id = " . $otp_record['id']);

                echo json_encode([
                    'success' => false,
                    'message' => 'Invalid OTP',
                    'remaining_attempts' => 3 - $new_attempts
                ]);
            }

        } else {
            // Check session fallback
            if (isset($_SESSION['login_otp']) && $_SESSION['login_mobile'] == $mobile) {
                if ($_SESSION['login_otp'] == $entered_otp) {
                    // Start user session
                    $_SESSION['user_mobile'] = $mobile;
                    // ... (rest of logic from your code)

                    echo json_encode([
                        'success' => true,
                        'message' => 'Login successful (via session)',
                    ]);
                } else {
                    throw new Exception('Invalid OTP (Session)');
                }
            } else {
                throw new Exception('No valid OTP found or it expired.');
            }
        }

    } catch (Exception $e) {
        error_log("Verify OTP Error: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}

$conn->close();
?>