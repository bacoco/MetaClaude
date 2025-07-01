# Database & Storage Encryption Guide

This comprehensive guide covers encryption strategies for databases and file storage systems, including implementation details, migration strategies, and performance considerations.

## Table of Contents
1. [Database Encryption Strategies](#database-encryption-strategies)
2. [Database-Specific Implementations](#database-specific-implementations)
3. [File Storage Encryption](#file-storage-encryption)
4. [Migration Strategies](#migration-strategies)
5. [Performance Considerations](#performance-considerations)
6. [Security Best Practices](#security-best-practices)

## Database Encryption Strategies

### 1. Transparent Data Encryption (TDE)

TDE encrypts data at the storage level, providing encryption at rest without application changes.

#### Benefits
- No application code changes required
- Automatic encryption/decryption
- Protects against physical theft of storage media
- Performance optimized at database engine level

#### Implementation Example
```sql
-- SQL Server TDE
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Strong_Password_123!';
CREATE CERTIFICATE TDECert WITH SUBJECT = 'TDE Certificate';
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;
ALTER DATABASE YourDatabase SET ENCRYPTION ON;
```

### 2. Column-Level Encryption

Encrypts specific sensitive columns while leaving other data unencrypted.

#### Use Cases
- PII (Personally Identifiable Information)
- Financial data (credit cards, bank accounts)
- Health records (HIPAA compliance)
- Authentication credentials

#### Implementation Pattern
```javascript
// Application-level column encryption
class ColumnEncryption {
  constructor(encryptionKey) {
    this.cipher = crypto.createCipher('aes-256-gcm', encryptionKey);
  }

  encryptColumn(plaintext) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.key, iv);
    
    let encrypted = cipher.update(plaintext, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted: encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    };
  }

  decryptColumn(encryptedData) {
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm', 
      this.key, 
      Buffer.from(encryptedData.iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
    
    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}
```

### 3. Application-Level Encryption

Encryption handled entirely by the application before data reaches the database.

#### Architecture
```javascript
// Encryption service with key rotation support
class ApplicationEncryption {
  constructor(kmsClient) {
    this.kms = kmsClient;
    this.keyCache = new Map();
  }

  async encryptData(data, context) {
    // Get or generate data encryption key
    const dataKey = await this.getDataEncryptionKey(context);
    
    // Encrypt data
    const encrypted = await this.performEncryption(data, dataKey);
    
    // Return encrypted data with key reference
    return {
      ciphertext: encrypted.ciphertext,
      keyId: dataKey.keyId,
      algorithm: 'AES-256-GCM',
      iv: encrypted.iv,
      authTag: encrypted.authTag
    };
  }

  async getDataEncryptionKey(context) {
    // Check cache first
    const cacheKey = `${context.tenant}:${context.keyVersion}`;
    if (this.keyCache.has(cacheKey)) {
      return this.keyCache.get(cacheKey);
    }

    // Generate new data encryption key
    const dataKey = await this.kms.generateDataKey({
      KeyId: context.masterKeyId,
      KeySpec: 'AES_256'
    });

    // Cache the key
    this.keyCache.set(cacheKey, {
      keyId: dataKey.KeyId,
      plaintext: dataKey.Plaintext,
      ciphertext: dataKey.CiphertextBlob
    });

    return this.keyCache.get(cacheKey);
  }
}
```

### 4. Encrypted Backups

Ensuring backups are encrypted both in transit and at rest.

```bash
# PostgreSQL encrypted backup
PGPASSWORD=$DB_PASSWORD pg_dump \
  -h localhost \
  -U postgres \
  -d mydb | \
  openssl enc -aes-256-cbc \
  -salt \
  -pass pass:$BACKUP_PASSWORD \
  -out backup.sql.enc

# Restore encrypted backup
openssl enc -d -aes-256-cbc \
  -salt \
  -pass pass:$BACKUP_PASSWORD \
  -in backup.sql.enc | \
  PGPASSWORD=$DB_PASSWORD psql \
  -h localhost \
  -U postgres \
  -d mydb
```

### 5. Query Encryption

Protecting queries in transit and enabling searchable encryption.

```javascript
// Searchable encryption implementation
class SearchableEncryption {
  constructor(masterKey) {
    this.masterKey = masterKey;
  }

  // Generate deterministic encryption for searchable fields
  generateSearchToken(plaintext) {
    const hmac = crypto.createHmac('sha256', this.masterKey);
    hmac.update(plaintext.toLowerCase().trim());
    return hmac.digest('hex');
  }

  // Encrypt with both random and deterministic encryption
  encryptSearchable(plaintext) {
    return {
      // Random encryption for storage
      ciphertext: this.randomEncrypt(plaintext),
      // Deterministic token for searching
      searchToken: this.generateSearchToken(plaintext)
    };
  }

  // Search query
  buildSearchQuery(searchTerm) {
    const token = this.generateSearchToken(searchTerm);
    return {
      where: { searchToken: token }
    };
  }
}
```

## Database-Specific Implementations

### PostgreSQL with pgcrypto

```sql
-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create encrypted table
CREATE TABLE sensitive_data (
    id SERIAL PRIMARY KEY,
    -- Symmetric encryption for sensitive data
    encrypted_ssn BYTEA,
    -- One-way hash for passwords
    password_hash TEXT,
    -- Deterministic encryption for searchable data
    email_hash TEXT,
    encrypted_email BYTEA,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert encrypted data
INSERT INTO sensitive_data (encrypted_ssn, password_hash, email_hash, encrypted_email)
VALUES (
    pgp_sym_encrypt('123-45-6789', 'encryption_key'),
    crypt('user_password', gen_salt('bf')),
    encode(digest('user@example.com', 'sha256'), 'hex'),
    pgp_sym_encrypt('user@example.com', 'encryption_key')
);

-- Query encrypted data
SELECT 
    pgp_sym_decrypt(encrypted_ssn, 'encryption_key') as ssn,
    pgp_sym_decrypt(encrypted_email, 'encryption_key') as email
FROM sensitive_data
WHERE email_hash = encode(digest('user@example.com', 'sha256'), 'hex');

-- Verify password
SELECT id FROM sensitive_data 
WHERE password_hash = crypt('user_password', password_hash);
```

### MySQL with Encryption Functions

```sql
-- MySQL 8.0+ encryption functions
CREATE TABLE encrypted_user_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255),
    -- AES encryption for sensitive data
    encrypted_ssn VARBINARY(255),
    -- SHA2 for searchable hashes
    email_hash VARCHAR(64),
    encrypted_email VARBINARY(255),
    -- Key ID for key rotation
    key_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create key ring for encryption keys
CREATE TABLE encryption_keys (
    key_id INT PRIMARY KEY,
    key_value VARBINARY(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'rotating', 'retired') DEFAULT 'active'
);

-- Insert encrypted data with key rotation support
DELIMITER $$
CREATE PROCEDURE insert_encrypted_user(
    IN p_username VARCHAR(255),
    IN p_ssn VARCHAR(11),
    IN p_email VARCHAR(255)
)
BEGIN
    DECLARE v_key_id INT;
    DECLARE v_key_value VARBINARY(32);
    
    -- Get active encryption key
    SELECT key_id, key_value INTO v_key_id, v_key_value
    FROM encryption_keys
    WHERE status = 'active'
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Insert encrypted data
    INSERT INTO encrypted_user_data (
        username,
        encrypted_ssn,
        email_hash,
        encrypted_email,
        key_id
    ) VALUES (
        p_username,
        AES_ENCRYPT(p_ssn, v_key_value),
        SHA2(LOWER(p_email), 256),
        AES_ENCRYPT(p_email, v_key_value),
        v_key_id
    );
END$$
DELIMITER ;

-- Decrypt data
SELECT 
    username,
    AES_DECRYPT(encrypted_ssn, k.key_value) as ssn,
    AES_DECRYPT(encrypted_email, k.key_value) as email
FROM encrypted_user_data u
JOIN encryption_keys k ON u.key_id = k.key_id
WHERE u.email_hash = SHA2(LOWER('user@example.com'), 256);
```

### MongoDB Field-Level Encryption

```javascript
// MongoDB client-side field level encryption
const { MongoClient } = require('mongodb');
const { ClientEncryption } = require('mongodb-client-encryption');

class MongoFieldEncryption {
  async initialize() {
    // KMS provider configuration
    const kmsProviders = {
      aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      }
    };

    // Create encryption client
    this.encryption = new ClientEncryption(client, {
      keyVaultNamespace: 'encryption.__keyVault',
      kmsProviders
    });

    // Create data key
    this.dataKeyId = await this.encryption.createDataKey('aws', {
      masterKey: {
        region: 'us-east-1',
        key: process.env.AWS_KMS_KEY_ID
      }
    });
  }

  // Schema for automatic encryption
  getEncryptedSchema() {
    return {
      bsonType: 'object',
      encryptMetadata: {
        keyId: [this.dataKeyId]
      },
      properties: {
        ssn: {
          encrypt: {
            bsonType: 'string',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
          }
        },
        medicalRecords: {
          encrypt: {
            bsonType: 'object',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
          }
        },
        creditCard: {
          encrypt: {
            bsonType: 'string',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
          }
        }
      }
    };
  }

  // Create encrypted collection
  async createEncryptedCollection() {
    const encryptedFields = {
      fields: [
        {
          path: 'ssn',
          bsonType: 'string',
          queries: { queryType: 'equality' }
        },
        {
          path: 'creditCard',
          bsonType: 'string'
        }
      ]
    };

    await db.createCollection('users', {
      encryptedFields,
      validator: { $jsonSchema: this.getEncryptedSchema() }
    });
  }

  // Manual encryption for complex scenarios
  async manuallyEncrypt(data) {
    const encrypted = await this.encryption.encrypt(
      data,
      {
        keyId: this.dataKeyId,
        algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
      }
    );
    return encrypted;
  }
}
```

### Redis Encryption

```javascript
// Redis encryption wrapper
class RedisEncryption {
  constructor(redisClient, encryptionKey) {
    this.redis = redisClient;
    this.encryptionKey = encryptionKey;
  }

  // Encrypt value before storing
  async setEncrypted(key, value, options = {}) {
    const serialized = JSON.stringify(value);
    const encrypted = this.encrypt(serialized);
    
    const data = {
      ciphertext: encrypted.ciphertext,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
      timestamp: Date.now()
    };
    
    if (options.ttl) {
      await this.redis.setex(key, options.ttl, JSON.stringify(data));
    } else {
      await this.redis.set(key, JSON.stringify(data));
    }
  }

  // Decrypt value after retrieving
  async getEncrypted(key) {
    const data = await this.redis.get(key);
    if (!data) return null;
    
    const parsed = JSON.parse(data);
    const decrypted = this.decrypt(parsed);
    
    return JSON.parse(decrypted);
  }

  // Encrypt Redis dumps for backup
  async createEncryptedDump() {
    const dump = await this.redis.bgsave();
    
    // Wait for dump to complete
    while (true) {
      const [saving] = await this.redis.lastsave();
      if (!saving) break;
      await new Promise(r => setTimeout(r, 1000));
    }
    
    // Encrypt the dump file
    const dumpPath = '/var/lib/redis/dump.rdb';
    const encryptedPath = '/backup/redis-encrypted.rdb';
    
    await this.encryptFile(dumpPath, encryptedPath);
    
    return encryptedPath;
  }

  encrypt(plaintext) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    
    let ciphertext = cipher.update(plaintext, 'utf8', 'base64');
    ciphertext += cipher.final('base64');
    
    return {
      ciphertext,
      iv: iv.toString('base64'),
      authTag: cipher.getAuthTag().toString('base64')
    };
  }

  decrypt(encrypted) {
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm',
      this.encryptionKey,
      Buffer.from(encrypted.iv, 'base64')
    );
    
    decipher.setAuthTag(Buffer.from(encrypted.authTag, 'base64'));
    
    let plaintext = decipher.update(encrypted.ciphertext, 'base64', 'utf8');
    plaintext += decipher.final('utf8');
    
    return plaintext;
  }
}
```

## File Storage Encryption

### S3 Server-Side Encryption

```javascript
// S3 encryption configuration
class S3Encryption {
  constructor() {
    this.s3 = new AWS.S3({
      region: process.env.AWS_REGION
    });
  }

  // Server-side encryption with S3-managed keys (SSE-S3)
  async uploadWithSSES3(bucket, key, body) {
    const params = {
      Bucket: bucket,
      Key: key,
      Body: body,
      ServerSideEncryption: 'AES256'
    };
    
    return await this.s3.upload(params).promise();
  }

  // Server-side encryption with KMS (SSE-KMS)
  async uploadWithSSEKMS(bucket, key, body, kmsKeyId) {
    const params = {
      Bucket: bucket,
      Key: key,
      Body: body,
      ServerSideEncryption: 'aws:kms',
      SSEKMSKeyId: kmsKeyId,
      // Optional: Add encryption context
      SSEKMSEncryptionContext: JSON.stringify({
        Department: 'Finance',
        Project: 'Sensitive-Data'
      })
    };
    
    return await this.s3.upload(params).promise();
  }

  // Server-side encryption with customer keys (SSE-C)
  async uploadWithSSEC(bucket, key, body, customerKey) {
    const params = {
      Bucket: bucket,
      Key: key,
      Body: body,
      SSECustomerAlgorithm: 'AES256',
      SSECustomerKey: customerKey,
      SSECustomerKeyMD5: this.calculateMD5(customerKey)
    };
    
    return await this.s3.upload(params).promise();
  }

  // Configure bucket default encryption
  async setBucketEncryption(bucket, kmsKeyId) {
    const params = {
      Bucket: bucket,
      ServerSideEncryptionConfiguration: {
        Rules: [{
          ApplyServerSideEncryptionByDefault: {
            SSEAlgorithm: 'aws:kms',
            KMSMasterKeyID: kmsKeyId
          },
          BucketKeyEnabled: true
        }]
      }
    };
    
    return await this.s3.putBucketEncryption(params).promise();
  }

  calculateMD5(key) {
    return crypto.createHash('md5').update(key).digest('base64');
  }
}
```

### Client-Side Encryption for Uploads

```javascript
// Client-side encryption before upload
class ClientSideEncryption {
  constructor(kmsClient) {
    this.kms = kmsClient;
    this.s3 = new AWS.S3();
  }

  async encryptAndUpload(file, bucket, key) {
    // Generate data encryption key
    const dataKey = await this.kms.generateDataKey({
      KeyId: process.env.KMS_KEY_ID,
      KeySpec: 'AES_256'
    }).promise();

    // Encrypt file
    const encryptedData = await this.encryptFile(
      file,
      dataKey.Plaintext
    );

    // Create metadata
    const metadata = {
      'x-amz-meta-cek': dataKey.CiphertextBlob.toString('base64'),
      'x-amz-meta-iv': encryptedData.iv.toString('base64'),
      'x-amz-meta-algorithm': 'AES-256-GCM',
      'x-amz-meta-key-id': process.env.KMS_KEY_ID
    };

    // Upload encrypted file
    const uploadParams = {
      Bucket: bucket,
      Key: key,
      Body: encryptedData.ciphertext,
      Metadata: metadata,
      ContentType: file.mimetype
    };

    return await this.s3.upload(uploadParams).promise();
  }

  async encryptFile(file, key) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    
    const chunks = [];
    
    return new Promise((resolve, reject) => {
      file.stream()
        .pipe(cipher)
        .on('data', chunk => chunks.push(chunk))
        .on('end', () => {
          const ciphertext = Buffer.concat(chunks);
          const authTag = cipher.getAuthTag();
          
          resolve({
            ciphertext,
            iv,
            authTag
          });
        })
        .on('error', reject);
    });
  }

  async downloadAndDecrypt(bucket, key) {
    // Get object with metadata
    const object = await this.s3.getObject({
      Bucket: bucket,
      Key: key
    }).promise();

    // Extract encryption metadata
    const encryptedKey = Buffer.from(
      object.Metadata['x-amz-meta-cek'],
      'base64'
    );
    const iv = Buffer.from(
      object.Metadata['x-amz-meta-iv'],
      'base64'
    );

    // Decrypt data encryption key
    const decryptedKey = await this.kms.decrypt({
      CiphertextBlob: encryptedKey
    }).promise();

    // Decrypt file
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm',
      decryptedKey.Plaintext,
      iv
    );

    const decrypted = Buffer.concat([
      decipher.update(object.Body),
      decipher.final()
    ]);

    return decrypted;
  }
}
```

### Encrypted File Streaming

```javascript
// Stream encryption for large files
class StreamEncryption {
  constructor(encryptionKey) {
    this.encryptionKey = encryptionKey;
  }

  createEncryptStream() {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-ctr', this.encryptionKey, iv);
    
    // Prepend IV to the stream
    const prependIV = new Transform({
      transform(chunk, encoding, callback) {
        if (!this.ivSent) {
          this.push(iv);
          this.ivSent = true;
        }
        this.push(chunk);
        callback();
      }
    });
    
    return {
      encryptStream: pipeline(prependIV, cipher, (err) => {
        if (err) console.error('Encryption pipeline error:', err);
      }),
      iv: iv
    };
  }

  createDecryptStream() {
    let iv;
    let ivBytesRead = 0;
    
    const extractIV = new Transform({
      transform(chunk, encoding, callback) {
        if (ivBytesRead < 16) {
          const bytesNeeded = 16 - ivBytesRead;
          const bytesToRead = Math.min(bytesNeeded, chunk.length);
          
          if (!iv) iv = Buffer.alloc(16);
          
          chunk.copy(iv, ivBytesRead, 0, bytesToRead);
          ivBytesRead += bytesToRead;
          
          if (ivBytesRead === 16) {
            this.decipher = crypto.createDecipheriv(
              'aes-256-ctr',
              this.encryptionKey,
              iv
            );
          }
          
          if (bytesToRead < chunk.length) {
            const remaining = chunk.slice(bytesToRead);
            this.push(this.decipher.update(remaining));
          }
        } else {
          this.push(this.decipher.update(chunk));
        }
        
        callback();
      }
    });
    
    return extractIV;
  }

  // Encrypt file stream to S3
  async encryptStreamToS3(readStream, bucket, key) {
    const { encryptStream, iv } = this.createEncryptStream();
    
    const upload = new AWS.S3.ManagedUpload({
      params: {
        Bucket: bucket,
        Key: key,
        Body: readStream.pipe(encryptStream),
        Metadata: {
          'encryption-iv': iv.toString('base64')
        }
      }
    });
    
    return await upload.promise();
  }

  // Decrypt file stream from S3
  async decryptStreamFromS3(bucket, key, writeStream) {
    const s3Stream = this.s3.getObject({
      Bucket: bucket,
      Key: key
    }).createReadStream();
    
    const decryptStream = this.createDecryptStream();
    
    return new Promise((resolve, reject) => {
      s3Stream
        .pipe(decryptStream)
        .pipe(writeStream)
        .on('finish', resolve)
        .on('error', reject);
    });
  }
}
```

### Secure Temporary Files

```javascript
// Secure temporary file handling
class SecureTempFiles {
  constructor(encryptionKey) {
    this.encryptionKey = encryptionKey;
    this.tempDir = '/secure/temp';
  }

  async createSecureTempFile(data, options = {}) {
    // Generate unique filename
    const filename = `${crypto.randomUUID()}.tmp`;
    const filepath = path.join(this.tempDir, filename);
    
    // Encrypt data
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(data),
      cipher.final()
    ]);
    
    const authTag = cipher.getAuthTag();
    
    // Write encrypted file with restricted permissions
    const fileData = Buffer.concat([
      iv,
      authTag,
      encrypted
    ]);
    
    await fs.promises.writeFile(filepath, fileData, {
      mode: 0o600 // Read/write for owner only
    });
    
    // Set auto-deletion
    if (options.ttl) {
      setTimeout(() => {
        this.secureDelete(filepath);
      }, options.ttl);
    }
    
    return {
      filepath,
      cleanup: () => this.secureDelete(filepath)
    };
  }

  async readSecureTempFile(filepath) {
    const fileData = await fs.promises.readFile(filepath);
    
    // Extract components
    const iv = fileData.slice(0, 16);
    const authTag = fileData.slice(16, 32);
    const encrypted = fileData.slice(32);
    
    // Decrypt
    const decipher = crypto.createDecipheriv('aes-256-gcm', this.encryptionKey, iv);
    decipher.setAuthTag(authTag);
    
    const decrypted = Buffer.concat([
      decipher.update(encrypted),
      decipher.final()
    ]);
    
    return decrypted;
  }

  async secureDelete(filepath) {
    try {
      // Overwrite file with random data multiple times
      const stats = await fs.promises.stat(filepath);
      const fileSize = stats.size;
      
      for (let i = 0; i < 3; i++) {
        const randomData = crypto.randomBytes(fileSize);
        await fs.promises.writeFile(filepath, randomData);
      }
      
      // Delete the file
      await fs.promises.unlink(filepath);
    } catch (error) {
      console.error('Secure delete failed:', error);
    }
  }

  // Memory-only temporary storage for ultra-sensitive data
  createMemoryStorage() {
    const storage = new Map();
    
    return {
      store: (key, data, ttl = 300000) => {
        const encrypted = this.encryptInMemory(data);
        storage.set(key, encrypted);
        
        setTimeout(() => {
          storage.delete(key);
        }, ttl);
      },
      
      retrieve: (key) => {
        const encrypted = storage.get(key);
        if (!encrypted) return null;
        
        return this.decryptFromMemory(encrypted);
      },
      
      delete: (key) => {
        storage.delete(key);
      },
      
      clear: () => {
        storage.clear();
      }
    };
  }

  encryptInMemory(data) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    
    const encrypted = Buffer.concat([
      cipher.update(Buffer.from(JSON.stringify(data))),
      cipher.final()
    ]);
    
    return {
      encrypted,
      iv,
      authTag: cipher.getAuthTag()
    };
  }

  decryptFromMemory(encryptedData) {
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm',
      this.encryptionKey,
      encryptedData.iv
    );
    
    decipher.setAuthTag(encryptedData.authTag);
    
    const decrypted = Buffer.concat([
      decipher.update(encryptedData.encrypted),
      decipher.final()
    ]);
    
    return JSON.parse(decrypted.toString());
  }
}
```

## Migration Strategies

### 1. Phased Migration Approach

```javascript
// Migration orchestrator
class EncryptionMigration {
  constructor(db, encryptionService) {
    this.db = db;
    this.encryption = encryptionService;
  }

  async executeMigration(tableName, columns) {
    // Phase 1: Add encrypted columns
    await this.addEncryptedColumns(tableName, columns);
    
    // Phase 2: Dual-write (write to both encrypted and unencrypted)
    await this.enableDualWrite(tableName, columns);
    
    // Phase 3: Backfill historical data
    await this.backfillData(tableName, columns);
    
    // Phase 4: Verify encryption
    await this.verifyEncryption(tableName, columns);
    
    // Phase 5: Switch reads to encrypted columns
    await this.switchReads(tableName, columns);
    
    // Phase 6: Stop dual writes
    await this.disableDualWrite(tableName, columns);
    
    // Phase 7: Drop unencrypted columns
    await this.dropUnencryptedColumns(tableName, columns);
  }

  async backfillData(tableName, columns) {
    const batchSize = 1000;
    let offset = 0;
    
    while (true) {
      const rows = await this.db.query(
        `SELECT id, ${columns.join(', ')} FROM ${tableName} 
         WHERE encrypted_flag = false 
         LIMIT ? OFFSET ?`,
        [batchSize, offset]
      );
      
      if (rows.length === 0) break;
      
      // Process batch
      const updates = await Promise.all(
        rows.map(async (row) => {
          const encrypted = {};
          
          for (const column of columns) {
            encrypted[`encrypted_${column}`] = await this.encryption.encrypt(
              row[column]
            );
          }
          
          return {
            id: row.id,
            ...encrypted
          };
        })
      );
      
      // Batch update
      await this.batchUpdate(tableName, updates);
      
      offset += batchSize;
      
      // Progress tracking
      console.log(`Migrated ${offset} rows...`);
      
      // Rate limiting
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }

  async verifyEncryption(tableName, columns) {
    // Sample verification
    const samples = await this.db.query(
      `SELECT * FROM ${tableName} ORDER BY RANDOM() LIMIT 100`
    );
    
    for (const row of samples) {
      for (const column of columns) {
        const decrypted = await this.encryption.decrypt(
          row[`encrypted_${column}`]
        );
        
        if (decrypted !== row[column]) {
          throw new Error(
            `Encryption verification failed for row ${row.id}, column ${column}`
          );
        }
      }
    }
    
    console.log('Encryption verification passed');
  }
}
```

### 2. Zero-Downtime Migration

```javascript
// Zero-downtime encryption migration
class ZeroDowntimeMigration {
  constructor(db, cache, encryptionService) {
    this.db = db;
    this.cache = cache;
    this.encryption = encryptionService;
  }

  async migrate(config) {
    // Step 1: Create shadow table
    await this.createShadowTable(config.table);
    
    // Step 2: Set up triggers for real-time sync
    await this.setupTriggers(config.table);
    
    // Step 3: Backfill with encryption
    await this.backfillWithProgress(config);
    
    // Step 4: Verify data consistency
    await this.verifyConsistency(config.table);
    
    // Step 5: Atomic switch
    await this.atomicSwitch(config.table);
    
    // Step 6: Cleanup
    await this.cleanup(config.table);
  }

  async setupTriggers(tableName) {
    // Create trigger for INSERT
    await this.db.query(`
      CREATE TRIGGER ${tableName}_encrypt_insert
      AFTER INSERT ON ${tableName}
      FOR EACH ROW
      EXECUTE FUNCTION encrypt_and_sync_row();
    `);
    
    // Create trigger for UPDATE
    await this.db.query(`
      CREATE TRIGGER ${tableName}_encrypt_update
      AFTER UPDATE ON ${tableName}
      FOR EACH ROW
      EXECUTE FUNCTION encrypt_and_sync_row();
    `);
    
    // Create trigger for DELETE
    await this.db.query(`
      CREATE TRIGGER ${tableName}_encrypt_delete
      AFTER DELETE ON ${tableName}
      FOR EACH ROW
      EXECUTE FUNCTION delete_encrypted_row();
    `);
  }

  async backfillWithProgress(config) {
    const totalRows = await this.getRowCount(config.table);
    const batchSize = config.batchSize || 1000;
    let processed = 0;
    
    // Use cursor for memory efficiency
    const cursor = await this.db.query(
      `DECLARE migration_cursor CURSOR FOR 
       SELECT * FROM ${config.table}`
    );
    
    while (true) {
      const batch = await this.db.query(
        `FETCH ${batchSize} FROM migration_cursor`
      );
      
      if (batch.length === 0) break;
      
      // Process batch in parallel
      await Promise.all(
        batch.map(row => this.encryptAndInsertRow(
          config.table,
          row,
          config.columns
        ))
      );
      
      processed += batch.length;
      
      // Update progress
      const progress = (processed / totalRows) * 100;
      await this.updateProgress(config.table, progress);
      
      // Adaptive rate limiting based on system load
      const delay = await this.calculateDelay();
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    await this.db.query('CLOSE migration_cursor');
  }

  async atomicSwitch(tableName) {
    const transaction = await this.db.beginTransaction();
    
    try {
      // Rename tables atomically
      await transaction.query(`
        ALTER TABLE ${tableName} RENAME TO ${tableName}_unencrypted;
        ALTER TABLE ${tableName}_encrypted RENAME TO ${tableName};
      `);
      
      // Update application cache
      await this.cache.flush(`${tableName}:*`);
      
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }

  calculateDelay() {
    // Adaptive delay based on system metrics
    const cpuUsage = process.cpuUsage();
    const memoryUsage = process.memoryUsage();
    
    if (cpuUsage.user > 80 || memoryUsage.heapUsed / memoryUsage.heapTotal > 0.9) {
      return 1000; // High load: 1 second delay
    } else if (cpuUsage.user > 50) {
      return 500; // Medium load: 500ms delay
    }
    
    return 100; // Low load: 100ms delay
  }
}
```

## Performance Considerations

### 1. Encryption Overhead Optimization

```javascript
// Performance-optimized encryption
class PerformanceOptimizedEncryption {
  constructor() {
    this.keyCache = new LRUCache({
      max: 1000,
      ttl: 1000 * 60 * 60 // 1 hour
    });
    
    this.cipherPool = this.createCipherPool();
  }

  // Cipher pooling for better performance
  createCipherPool() {
    const pool = [];
    const poolSize = 10;
    
    for (let i = 0; i < poolSize; i++) {
      pool.push({
        inUse: false,
        cipher: null,
        decipher: null
      });
    }
    
    return pool;
  }

  async encryptBatch(items, keyId) {
    // Get or generate bulk encryption key
    const key = await this.getBulkKey(keyId);
    
    // Process in parallel with worker threads
    const workers = os.cpus().length;
    const chunkSize = Math.ceil(items.length / workers);
    const chunks = [];
    
    for (let i = 0; i < items.length; i += chunkSize) {
      chunks.push(items.slice(i, i + chunkSize));
    }
    
    const encrypted = await Promise.all(
      chunks.map(chunk => 
        this.processChunkInWorker(chunk, key)
      )
    );
    
    return encrypted.flat();
  }

  // Hardware acceleration when available
  async encryptWithHardwareAcceleration(data, key) {
    try {
      // Check for AES-NI support
      if (crypto.constants.OPENSSL_VERSION_NUMBER >= 0x1000100f) {
        const cipher = crypto.createCipheriv(
          'aes-256-gcm',
          key,
          crypto.randomBytes(16),
          { authTagLength: 16 }
        );
        
        // Use hardware-accelerated AES
        cipher.setAAD(Buffer.from('additional-auth-data'));
        
        return cipher.update(data);
      }
    } catch (error) {
      // Fallback to software encryption
      return this.softwareEncrypt(data, key);
    }
  }

  // Caching strategies
  async getCachedOrEncrypt(key, data) {
    const cacheKey = `${key}:${crypto.createHash('md5').update(data).digest('hex')}`;
    
    // Check cache first
    const cached = this.cache.get(cacheKey);
    if (cached) return cached;
    
    // Encrypt and cache
    const encrypted = await this.encrypt(data);
    this.cache.set(cacheKey, encrypted);
    
    return encrypted;
  }
}
```

### 2. Query Performance Optimization

```javascript
// Optimized encrypted query patterns
class EncryptedQueryOptimizer {
  constructor(db, encryption) {
    this.db = db;
    this.encryption = encryption;
  }

  // Indexed searchable encryption
  async createSearchableIndex(table, column) {
    // Create hash index for deterministic encryption
    await this.db.query(`
      CREATE INDEX idx_${table}_${column}_hash 
      ON ${table} ((encode(digest(${column}, 'sha256'), 'hex')))
    `);
    
    // Create bloom filter for approximate matching
    await this.db.query(`
      CREATE INDEX idx_${table}_${column}_bloom 
      ON ${table} USING bloom (${column}_bloom)
    `);
  }

  // Optimized equality search
  async searchEqual(table, column, value) {
    const hash = this.encryption.deterministicHash(value);
    
    return await this.db.query(`
      SELECT * FROM ${table}
      WHERE ${column}_hash = ?
    `, [hash]);
  }

  // Prefix search with order-preserving encryption
  async searchPrefix(table, column, prefix) {
    const opePrefix = await this.encryption.orderPreservingEncrypt(prefix);
    
    return await this.db.query(`
      SELECT * FROM ${table}
      WHERE ${column}_ope >= ? 
      AND ${column}_ope < ?
    `, [opePrefix, this.incrementOPE(opePrefix)]);
  }

  // Range queries with homomorphic encryption
  async sumEncryptedColumn(table, column, conditions) {
    // Use homomorphic properties for aggregation
    const result = await this.db.query(`
      SELECT SUM(${column}_he) as encrypted_sum
      FROM ${table}
      WHERE ${conditions}
    `);
    
    // Decrypt the sum
    return this.encryption.homomorphicDecrypt(result[0].encrypted_sum);
  }

  // Batch decryption for better performance
  async batchDecryptResults(rows, columns) {
    const decryptionTasks = [];
    
    for (const row of rows) {
      for (const column of columns) {
        decryptionTasks.push({
          rowId: row.id,
          column: column,
          encrypted: row[column]
        });
      }
    }
    
    // Process in parallel batches
    const batchSize = 100;
    const results = new Map();
    
    for (let i = 0; i < decryptionTasks.length; i += batchSize) {
      const batch = decryptionTasks.slice(i, i + batchSize);
      const decrypted = await Promise.all(
        batch.map(task => this.encryption.decrypt(task.encrypted))
      );
      
      batch.forEach((task, index) => {
        if (!results.has(task.rowId)) {
          results.set(task.rowId, {});
        }
        results.get(task.rowId)[task.column] = decrypted[index];
      });
    }
    
    return results;
  }
}
```

### 3. Storage Optimization

```javascript
// Storage-optimized encryption
class StorageOptimizedEncryption {
  constructor() {
    this.compressionThreshold = 1024; // 1KB
  }

  // Compress before encryption for better storage
  async encryptWithCompression(data) {
    const shouldCompress = Buffer.byteLength(data) > this.compressionThreshold;
    
    let processedData = data;
    let isCompressed = false;
    
    if (shouldCompress) {
      processedData = await this.compress(data);
      isCompressed = true;
    }
    
    const encrypted = await this.encrypt(processedData);
    
    return {
      data: encrypted,
      metadata: {
        compressed: isCompressed,
        originalSize: Buffer.byteLength(data),
        encryptedSize: Buffer.byteLength(encrypted.ciphertext)
      }
    };
  }

  // Format-preserving encryption for structured data
  async encryptStructured(data, format) {
    switch (format) {
      case 'email':
        return this.encryptEmail(data);
      case 'phone':
        return this.encryptPhone(data);
      case 'ssn':
        return this.encryptSSN(data);
      case 'creditcard':
        return this.encryptCreditCard(data);
      default:
        return this.encrypt(data);
    }
  }

  encryptEmail(email) {
    const [localPart, domain] = email.split('@');
    const encryptedLocal = this.formatPreservingEncrypt(
      localPart,
      'alphanumeric'
    );
    
    // Keep domain for searching/grouping
    return `${encryptedLocal}@${domain}`;
  }

  encryptCreditCard(cardNumber) {
    // Keep first 6 (BIN) and last 4 for identification
    const bin = cardNumber.substring(0, 6);
    const lastFour = cardNumber.substring(cardNumber.length - 4);
    const middle = cardNumber.substring(6, cardNumber.length - 4);
    
    const encryptedMiddle = this.formatPreservingEncrypt(
      middle,
      'numeric'
    );
    
    return `${bin}${encryptedMiddle}${lastFour}`;
  }

  // Deduplication for encrypted data
  async deduplicateEncrypted(items) {
    const seen = new Set();
    const unique = [];
    
    for (const item of items) {
      // Generate deterministic fingerprint
      const fingerprint = await this.generateFingerprint(item);
      
      if (!seen.has(fingerprint)) {
        seen.add(fingerprint);
        unique.push(item);
      }
    }
    
    return unique;
  }
}
```

## Security Best Practices

### 1. Key Management

```javascript
// Secure key management
class KeyManagement {
  constructor(hsmClient) {
    this.hsm = hsmClient;
    this.keyRotationInterval = 90 * 24 * 60 * 60 * 1000; // 90 days
  }

  async generateMasterKey() {
    // Generate in HSM
    const key = await this.hsm.generateDataKey({
      KeySpec: 'AES_256',
      Purpose: 'ENCRYPT_DECRYPT',
      MultiRegion: true
    });
    
    // Set automatic rotation
    await this.hsm.enableKeyRotation({
      KeyId: key.KeyId,
      RotationPeriodInDays: 90
    });
    
    return key;
  }

  // Key derivation for multi-tenant environments
  async derivePerTenantKey(masterKey, tenantId) {
    const info = Buffer.from(`tenant-key-${tenantId}`);
    const salt = crypto.randomBytes(32);
    
    const derivedKey = await new Promise((resolve, reject) => {
      crypto.hkdf('sha256', masterKey, salt, info, 32, (err, key) => {
        if (err) reject(err);
        else resolve(key);
      });
    });
    
    // Cache with TTL
    await this.cacheKey(tenantId, derivedKey);
    
    return derivedKey;
  }

  // Emergency key escrow
  async setupKeyEscrow(keyId) {
    // Split key using Shamir's Secret Sharing
    const shares = await this.splitKey(keyId, {
      shares: 5,
      threshold: 3
    });
    
    // Distribute to different secure locations
    await Promise.all([
      this.storeShare(shares[0], 'hsm-1'),
      this.storeShare(shares[1], 'hsm-2'),
      this.storeShare(shares[2], 'secure-vault'),
      this.storeShare(shares[3], 'offline-backup'),
      this.storeShare(shares[4], 'disaster-recovery')
    ]);
  }
}
```

### 2. Audit and Compliance

```javascript
// Encryption audit logging
class EncryptionAudit {
  constructor(auditLogger) {
    this.logger = auditLogger;
  }

  async logEncryptionOperation(operation) {
    const auditEntry = {
      timestamp: new Date().toISOString(),
      operation: operation.type,
      user: operation.user,
      resource: operation.resource,
      keyId: operation.keyId,
      algorithm: operation.algorithm,
      success: operation.success,
      reason: operation.reason,
      // Include compliance metadata
      compliance: {
        gdpr: operation.gdprCompliant,
        pci: operation.pciCompliant,
        hipaa: operation.hipaaCompliant
      },
      // Cryptographic proof of integrity
      hash: this.generateAuditHash(operation)
    };
    
    // Log to immutable audit trail
    await this.logger.log(auditEntry);
    
    // Alert on suspicious patterns
    await this.detectAnomalies(auditEntry);
  }

  async generateComplianceReport(startDate, endDate) {
    const operations = await this.logger.query({
      startDate,
      endDate
    });
    
    return {
      summary: {
        totalOperations: operations.length,
        encryptionOperations: operations.filter(op => op.operation === 'encrypt').length,
        decryptionOperations: operations.filter(op => op.operation === 'decrypt').length,
        keyRotations: operations.filter(op => op.operation === 'key_rotation').length
      },
      compliance: {
        gdprCompliant: operations.every(op => op.compliance.gdpr),
        pciCompliant: operations.every(op => op.compliance.pci),
        hipaaCompliant: operations.every(op => op.compliance.hipaa)
      },
      recommendations: await this.generateRecommendations(operations)
    };
  }
}
```

This comprehensive guide provides production-ready implementations for database and storage encryption with focus on security, performance, and maintainability. Each section includes practical examples that can be adapted to specific use cases and requirements.