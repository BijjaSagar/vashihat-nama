<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

define('SECURE_ACCESS', true);

// Start session
session_start();
require_once 'includes/config.php';
require_once 'includes/function.php';

header('Content-Type: application/json');

// HSP SMS Service Configuration
define('HSP_SMS_USERNAME', '8983839143');
define('HSP_SMS_SENDER_ID', 'DASSAM');
define('HSP_SMS_TYPE', 'TRANS');
define('HSP_SMS_API_KEY', '514c77e1-4947-4a80-8689-59bcbf73b8ab');

/**
 * Send SMS using HSP SMS Service
 */
function sendSMS($phoneNumber, $message)
{
    $username = HSP_SMS_USERNAME;
    $senderName = HSP_SMS_SENDER_ID;
    $smsType = HSP_SMS_TYPE;
    $apiKey = HSP_SMS_API_KEY;

    $encodedMessage = urlencode($message);
    $url = "http://sms.hspsms.com/sendSMS?username=$username&message=$encodedMessage&sendername=$senderName&smstype=$smsType&numbers=$phoneNumber&apikey=$apiKey";

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_FOLLOWLOCATION => true,
    ]);

    $response = curl_exec($ch);

    if ($response === false) {
        $error = curl_error($ch);
        error_log("CURL Error: " . $error);
        curl_close($ch);
        return ['success' => false, 'message' => 'SMS sending failed: ' . $error];
    }

    curl_close($ch);
    error_log("SMS API Response: " . $response);

    return ['success' => true, 'message' => 'SMS sent'];
}

// Define sanitize_input if not exists
if (!function_exists('sanitize_input')) {
    function sanitize_input($data)
    {
        $data = trim($data);
        $data = stripslashes($data);
        $data = htmlspecialchars($data);
        return $data;
    }
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get JSON input because Flutter sends application/json
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);

    // Fallback to $_POST form-data if JSON is empty (for flexibility)
    if (!empty($data)) {
        $_POST = array_merge($_POST, $data);
    }

    try {
        $mobile = sanitize_input($_POST["mobile"] ?? $_POST["phone"] ?? ''); // Support 'mobile' or 'phone'

        // Validate mobile
        if (!preg_match("/^[6-9][0-9]{9}$/", $mobile)) {
            throw new Exception('Invalid mobile number format');
        }

        // Check if user exists (Optional: Depends on if you register users first)
        // For testing, we might want to allow sending OTP even if user doesn't exist yet?
        // But following your code:

        $stmt = $conn->prepare("SELECT id, name FROM users WHERE mobile = ?");
        if (!$stmt) {
            // If table doesn't exist, create it for testing locally?
            throw new Exception('Database error: ' . $conn->error);
        }

        $stmt->bind_param("s", $mobile);
        $stmt->execute();
        $result = $stmt->get_result();

        // IF USER DOES NOT EXIST, WE SHOULD PROBABLY STILL SEND OTP FOR REGISTRATION?
        // Your logic says: "If user exists -> send OTP. Else -> return register."

        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();

            // Delete any existing OTPs for this mobile
            $delete_stmt = $conn->prepare("DELETE FROM otp_verifications WHERE mobile = ?");
            $delete_stmt->bind_param("s", $mobile);
            $delete_stmt->execute();
            $delete_stmt->close();

            // Generate new OTP
            $otp = mt_rand(100000, 999999);

            // Insert OTP into database
            $insert_stmt = $conn->prepare("INSERT INTO otp_verifications (mobile, otp, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))");
            if (!$insert_stmt) {
                throw new Exception('Database error: ' . $conn->error);
            }

            $insert_stmt->bind_param("ss", $mobile, $otp);

            if (!$insert_stmt->execute()) {
                throw new Exception('Failed to save OTP: ' . $insert_stmt->error);
            }
            $insert_stmt->close();

            // Also store in session as backup
            $_SESSION['login_otp'] = $otp;
            $_SESSION['login_mobile'] = $mobile;
            $_SESSION['otp_time'] = time();
            $_SESSION['otp_attempts'] = 0;

            // Prepare SMS message
            $message = "$otp is your OTP for login into your account. GGISKB";

            // Send SMS
            $smsResult = sendSMS($mobile, $message);

            echo json_encode([
                'success' => true,
                'message' => 'OTP sent successfully',
                'mobile' => substr($mobile, 0, 2) . 'XXXXXX' . substr($mobile, -2),
                'sms_status' => $smsResult['success'] ? 'sent' : 'failed'
            ]);

        } else {
            // User needs to register first
            echo json_encode([
                'success' => false,
                'message' => 'Mobile number not registered.',
                'action' => 'register'
            ]);
        }

        $stmt->close();

    } catch (Exception $e) {
        error_log("Error in send_otp.php: " . $e->getMessage());

        echo json_encode([
            'success' => false,
            'message' => 'Error sending OTP: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}

if (isset($conn)) {
    $conn->close();
}
?>