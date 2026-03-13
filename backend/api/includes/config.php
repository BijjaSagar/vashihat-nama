<?php
// Database Configuration
define('DB_SERVER', getenv('DB_HOST') ?: 'localhost');
define('DB_USERNAME', getenv('DB_USER') ?: 'root');
define('DB_PASSWORD', getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('DB_NAME') ?: 'vasihat_nama');

// Attempt to connect to MySQL database
$conn = new mysqli(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die("ERROR: Could not connect. " . $conn->connect_error);
}

// Function helper placeholder since your code requires includes/function.php
// If you have specific functions in function.php, add them here or created the file.
?>