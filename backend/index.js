require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// AWS S3 Configuration
const s3Client = new S3Client({
    region: process.env.AWS_DEFAULT_REGION,
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    },
});

// Endpoint: Health Check
app.get('/', (req, res) => {
    res.send('Vasihat Nama Backend is Running (Node.js)');
});

// Endpoint: Get Presigned URL
app.post('/api/get-presigned-url', async (req, res) => {
    try {
        const { fileName, fileType } = req.body;

        if (!fileName || !fileType) {
            return res.status(400).json({ message: 'Missing fileName or fileType' });
        }

        const bucketName = process.env.AWS_BUCKET;
        const key = `uploads/${Date.now()}_${fileName}`;

        const command = new PutObjectCommand({
            Bucket: bucketName,
            Key: key,
            ContentType: fileType,
        });

        // Generate Presigned URL (valid for 20 minutes)
        const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn: 1200 });

        res.json({
            url: presignedUrl,
            key: key,
            bucket: bucketName,
        });

    } catch (error) {
        console.error('Error serving presigned URL:', error);
        res.status(500).json({ message: 'Internal Server Error', error: error.message });
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
