#!/usr/bin/env node
/**
 * Test script for dibbs-ecr-refiner deployment
 * Uploads a test file to S3
 */

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');

// Initialize AWS clients
const s3Client = new S3Client();

async function main() {
    // Configuration
    const bucketName = process.env.S3_BUCKET_NAME || 'data-repository';
    const testContent = "Hello, World! This is a test file for dibbs-aims-helloworld.";
    const testFilename = `helloworld_${uuidv4().substring(0, 8)}.txt`;
    
    console.log('🚀 Starting test for dibbs-aims-helloworld');
    console.log(`📦 S3 Bucket: ${bucketName}`);
    console.log(`📄 Test file: ${testFilename}`);
    
    try {
        // Step 1: Upload test file to RefinerInput
        const inputKey = `RefinerInput/${testFilename}`;
        console.log(`\n📤 Uploading test file to s3://${bucketName}/${inputKey}`);
        
        const putCommand = new PutObjectCommand({
            Bucket: bucketName,
            Key: inputKey,
            Body: testContent,
            ContentType: 'text/plain'
        });
        
        await s3Client.send(putCommand);
        
        console.log('✅ Test file uploaded successfully');
    } catch (error) {
        console.error('❌ Unexpected error:', error);
        process.exit(1);
    }
}
// Run the main function
main().catch(error => {
    console.error('❌ Unexpected error:', error);
    process.exit(1);
});