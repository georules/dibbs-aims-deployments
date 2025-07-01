const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');

// Initialize AWS clients
const s3Client = new S3Client();

exports.handler = async (event) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    try {
        // Process each SQS message
        for (const record of event.Records) {
            await processMessage(record);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Processing completed successfully' })
        };
    } catch (error) {
        console.error('Error processing messages:', error);
        throw error;
    }
};

async function processMessage(record) {
    try {
        // Parse SQS message body (contains S3 event)
        const s3Event = JSON.parse(record.body);
        console.log('S3 Event:', JSON.stringify(s3Event, null, 2));
        
        // Extract S3 object information
        const s3Record = s3Event.detail;
        const bucketName = s3Record.bucket.name;
        const objectKey = s3Record.object.key;
        
        console.log(`Processing file: s3://${bucketName}/${objectKey}`);
        
        // Read the input file from S3
        const inputContent = await readS3Object(bucketName, objectKey);
        console.log(`Input file content: ${inputContent}`);
        
        // Generate two UUIDs
        const uuid1 = uuidv4();
        const uuid2 = uuidv4();
        console.log(`Generated UUIDs: ${uuid1}, ${uuid2}`);
        
        // Get environment variables
        const outputPrefix = process.env.REFINER_OUTPUT_PREFIX || 'RefinerOutput/';
        const completePrefix = process.env.REFINER_COMPLETE_PREFIX || 'RefinerComplete/';
        
        // Write two output files with the same content
        const outputKey1 = `${outputPrefix}${uuid1}.txt`;
        const outputKey2 = `${outputPrefix}${uuid2}.txt`;
        
        await writeS3Object(bucketName, outputKey1, inputContent);
        await writeS3Object(bucketName, outputKey2, inputContent);
        
        console.log(`Output files created: ${outputKey1}, ${outputKey2}`);
        
        // Create completion JSON file
        const filename = objectKey.split('/').pop(); // Get filename from input path
        const completeKey = `${completePrefix}${filename}.json`;
        const completeContent = JSON.stringify([outputKey1, outputKey2]);
        
        await writeS3Object(bucketName, completeKey, completeContent);
        
        console.log(`Completion file created: ${completeKey}`);
        console.log(`Completion file content: ${completeContent}`);
        
    } catch (error) {
        console.error('Error processing message:', error);
        throw error;
    }
}

async function readS3Object(bucket, key) {
    try {
        const command = new GetObjectCommand({
            Bucket: bucket,
            Key: key
        });
        
        const response = await s3Client.send(command);
        const bodyContents = await response.Body.transformToString();
        return bodyContents;
    } catch (error) {
        console.error(`Error reading S3 object s3://${bucket}/${key}:`, error);
        throw error;
    }
}

async function writeS3Object(bucket, key, content) {
    try {
        const command = new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: content,
            ContentType: 'text/plain'
        });
        
        await s3Client.send(command);
        console.log(`Successfully wrote to s3://${bucket}/${key}`);
    } catch (error) {
        console.error(`Error writing S3 object s3://${bucket}/${key}:`, error);
        throw error;
    }
} 