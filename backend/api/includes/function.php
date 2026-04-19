<?php
// Helper functions for Vasihat Nama Backend

function isLocalDevelopment()
{
    return $_SERVER['HTTP_HOST'] === 'localhost' || $_SERVER['HTTP_HOST'] === '127.0.0.1';
}

function handleLocalOTP($mobile, $otp)
{
    // Log OTP for local dev
    error_log("LOCAL DEV OTP for $mobile: $otp");
}
?>