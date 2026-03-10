<?php
require 'vendor/autoload.php';

use Aws\S3\S3Client;
use Aws\Exception\AwsException;
use Dotenv\Dotenv;

// Initialize Dotenv to read .env file
$dotenv = Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->safeLoad();

// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->fileName) || !isset($data->fileType)) {
    http_response_code(400);
    echo json_encode(["message" => "Missing fileName or fileType."]);
    exit();
}

$fileName = $data->fileName;
$fileType = $data->fileType;
$bucket = $_ENV['AWS_BUCKET'];

// Configure S3 Client
$s3Client = new S3Client([
    'region'  => $_ENV['AWS_DEFAULT_REGION'],
    'version' => 'latest',
    'credentials' => [
        'key'    => $_ENV['AWS_ACCESS_KEY_ID'],
        'secret' => $_ENV['AWS_SECRET_ACCESS_KEY'],
    ],
]);

try {
    // Generate a unique file name
    $key = 'uploads/' . uniqid() . '_' . $fileName;

    // Create a command to PutObject
    $cmd = $s3Client->getCommand('PutObject', [
        'Bucket' => $bucket,
        'Key'    => $key,
        'ContentType' => $fileType,
        // 'ACL'    => 'public-read', // Optional: Depends on bucket policy
    ]);

    // Create a pre-signed URL that expires in 20 minutes
    $request = $s3Client->createPresignedRequest($cmd, '+20 minutes');
    $presignedUrl = (string)$request->getUri();

    echo json_encode([
        "url" => $presignedUrl,
        "key" => $key,
        "bucket" => $bucket
    ]);

} catch (AwsException $e) {
    http_response_code(500);
    echo json_encode(["message" => "Error generating pre-signed URL: " . $e->getMessage()]);
}
