#!/usr/bin/env node
/**
 * Polling script for dibbs-ecr-refiner completion files
 * Monitors the RefinerComplete folder and downloads output files
 */

const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');

// Initialize AWS clients
const s3Client = new S3Client();

async function main() {
    // Configuration
    const bucketName = process.env.S3_BUCKET_NAME || 'data-repository';
    const completionPrefix = 'RefinerComplete/';
    const pollInterval = 10; // seconds
    const maxPollTime = 300; // 5 minutes
    
    console.log('🔍 Starting completion file poller');
    console.log(`📦 S3 Bucket: ${bucketName}`);
    console.log(`📁 Completion prefix: ${completionPrefix}`);
    console.log(`⏱️  Poll interval: ${pollInterval}s`);
    console.log(`⏰ Max poll time: ${maxPollTime}s`);
    
    const startTime = new Date();
    const processedFiles = new Set();
    
    try {
        while ((new Date() - startTime) / 1000 < maxPollTime) {
            console.log('\n🔍 Polling for new completion files...');
            
            // List objects in RefinerComplete folder
            const listCommand = new ListObjectsV2Command({
                Bucket: bucketName,
                Prefix: completionPrefix
            });
            
            const response = await s3Client.send(listCommand);
            
            if (response.Contents && response.Contents.length > 0) {
                for (const obj of response.Contents) {
                    const key = obj.Key;
                    
                    // Skip if already processed
                    if (processedFiles.has(key)) {
                        continue;
                    }
                    
                    // Only process JSON files
                    if (!key.endsWith('.json')) {
                        continue;
                    }
                    
                    console.log(`📄 Found new completion file: ${key}`);
                    
                    try {
                        // Download and parse completion file
                        const getCommand = new GetObjectCommand({
                            Bucket: bucketName,
                            Key: key
                        });
                        
                        const completionResponse = await s3Client.send(getCommand);
                        const bodyContents = await completionResponse.Body.transformToString();
                        const completionData = JSON.parse(bodyContents);
                        
                        console.log(`📋 Completion data: ${JSON.stringify(completionData)}`);
                        
                        // Download each output file
                        for (const outputKey of completionData) {
                            console.log(`📥 Downloading output file: ${outputKey}`);
                            
                            try {
                                const outputGetCommand = new GetObjectCommand({
                                    Bucket: bucketName,
                                    Key: outputKey
                                });
                                
                                const outputResponse = await s3Client.send(outputGetCommand);
                                const outputContent = await outputResponse.Body.transformToString();
                                console.log(`📝 Output file content: ${outputContent}`);
                                
                            } catch (error) {
                                console.error(`❌ Error downloading output file ${outputKey}: ${error.message}`);
                            }
                        }
                        
                        // Mark as processed
                        processedFiles.add(key);
                        console.log(`✅ Successfully processed completion file: ${key}`);
                        
                    } catch (error) {
                        console.error(`❌ Error processing completion file ${key}: ${error.message}`);
                    }
                }
            } else {
                console.log('📭 No completion files found');
            }
            
            // Wait before next poll
            console.log(`⏳ Waiting ${pollInterval} seconds before next poll...`);
            await new Promise(resolve => setTimeout(resolve, pollInterval * 1000));
        }
        
        console.log('\n⏰ Polling completed (max time reached)');
        console.log('📊 Summary:');
        console.log(`   - Files processed: ${processedFiles.size}`);
        console.log(`   - Total poll time: ${((new Date() - startTime) / 1000).toFixed(1)}s`);
        
    } catch (error) {
        console.error(`❌ Polling failed with error: ${error.message}`);
        process.exit(1);
    }
}

// Handle process interruption
process.on('SIGINT', () => {
    console.log('\n🛑 Polling interrupted by user');
    process.exit(0);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Run the main function
main().catch(error => {
    console.error('❌ Unexpected error:', error);
    process.exit(1);
}); 