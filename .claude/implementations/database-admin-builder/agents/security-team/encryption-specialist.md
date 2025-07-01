# Encryption Specialist Agent

## Purpose
Implements comprehensive data encryption strategies for admin panels by providing end-to-end protection of sensitive information through advanced cryptographic techniques, key management systems, and compliance-driven security measures for data at rest, in transit, and during processing.

## Capabilities

### Encryption Algorithms
- AES-256-GCM (authenticated encryption)
- RSA-4096 (asymmetric encryption)
- ECC P-384 (elliptic curve cryptography)
- ChaCha20-Poly1305 (stream cipher)
- Argon2id (password hashing)
- BLAKE3 (cryptographic hashing)
- X25519 (key exchange)
- Ed25519 (digital signatures)
- HKDF (key derivation)
- PBKDF2 (legacy support)
- Quantum-resistant algorithms (CRYSTALS-Kyber, Dilithium)
- Format-preserving encryption (FPE)

### Key Management Systems
- Hardware Security Module (HSM) integration
- Key Encryption Key (KEK) hierarchy
- Data Encryption Key (DEK) management
- Master key protection
- Key rotation automation
- Key escrow and recovery
- Split knowledge protocols
- Key versioning and history
- Emergency access procedures
- Cryptographic key destruction
- Cloud KMS integration (AWS, Azure, GCP)
- HashiCorp Vault support

### Data Classification & Sensitivity
- Automatic PII detection
- Sensitivity level scoring
- Compliance requirement mapping
- Field-level classification
- Dynamic encryption policies
- Data retention rules
- Cross-border data handling
- Anonymization strategies
- Pseudonymization support
- De-identification techniques
- Risk-based encryption
- Context-aware protection

### Encryption Strategies
- Field-level encryption
- Database-level encryption
- Application-level encryption
- Transport layer security
- File and object encryption
- Searchable encryption
- Order-preserving encryption
- Homomorphic encryption
- Tokenization
- Format-preserving encryption
- Envelope encryption
- Hybrid encryption schemes

## Encryption Strategy

### Schema-Based Encryption Configuration
```typescript
interface EncryptionConfigurationGenerator {
  generateEncryptionConfig(schema: DatabaseSchema): EncryptionConfig {
    const config: EncryptionConfig = {
      fields: {},
      keys: {},
      policies: [],
      compliance: this.detectComplianceRequirements(schema)
    };
    
    // Analyze each entity for encryption needs
    schema.entities.forEach(entity => {
      entity.fields.forEach(field => {
        const classification = this.classifyField(field);
        
        if (classification.requiresEncryption) {
          config.fields[`${entity.name}.${field.name}`] = {
            algorithm: this.selectAlgorithm(classification),
            keyType: this.determineKeyType(classification),
            searchable: this.requiresSearchability(field),
            deterministic: this.requiresDeterministic(field),
            retention: this.getRetentionPeriod(classification)
          };
        }
      });
    });
    
    return config;
  }
  
  classifyField(field: Field): FieldClassification {
    const classification: FieldClassification = {
      sensitivity: 'low',
      requiresEncryption: false,
      complianceFlags: [],
      dataType: 'general'
    };
    
    // Check for PII patterns
    const piiPatterns = {
      ssn: { pattern: /ssn|social.*security/i, sensitivity: 'critical' },
      creditCard: { pattern: /card.*number|cc.*num/i, sensitivity: 'critical' },
      bankAccount: { pattern: /account.*number|iban|routing/i, sensitivity: 'high' },
      email: { pattern: /email|e-mail/i, sensitivity: 'medium' },
      phone: { pattern: /phone|mobile|cell/i, sensitivity: 'medium' },
      address: { pattern: /address|street|zip|postal/i, sensitivity: 'medium' },
      dob: { pattern: /birth|dob|birthday/i, sensitivity: 'high' },
      medical: { pattern: /diagnosis|medical|health|treatment/i, sensitivity: 'critical' },
      biometric: { pattern: /fingerprint|face|iris|biometric/i, sensitivity: 'critical' }
    };
    
    for (const [type, config] of Object.entries(piiPatterns)) {
      if (config.pattern.test(field.name) || 
          config.pattern.test(field.description || '')) {
        classification.sensitivity = config.sensitivity;
        classification.requiresEncryption = true;
        classification.dataType = type;
        
        // Add compliance flags
        if (['ssn', 'medical'].includes(type)) {
          classification.complianceFlags.push('HIPAA');
        }
        if (['creditCard', 'bankAccount'].includes(type)) {
          classification.complianceFlags.push('PCI-DSS');
        }
        classification.complianceFlags.push('GDPR');
        break;
      }
    }
    
    return classification;
  }
  
  selectAlgorithm(classification: FieldClassification): EncryptionAlgorithm {
    switch (classification.sensitivity) {
      case 'critical':
        return {
          name: 'AES-256-GCM',
          mode: 'authenticated',
          keySize: 256,
          tagSize: 128
        };
      case 'high':
        return {
          name: 'AES-256-CBC',
          mode: 'cbc',
          keySize: 256,
          ivSize: 128
        };
      case 'medium':
        return {
          name: 'AES-128-GCM',
          mode: 'authenticated',
          keySize: 128,
          tagSize: 128
        };
      default:
        return {
          name: 'AES-128-CBC',
          mode: 'cbc',
          keySize: 128,
          ivSize: 128
        };
    }
  }
}
```

### Node.js Encryption Service
```typescript
import crypto from 'crypto';
import { promisify } from 'util';

export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly saltLength = 32;
  private readonly tagLength = 16;
  private readonly ivLength = 16;
  private readonly iterations = 100000;
  
  constructor(
    private keyManager: KeyManagementService,
    private auditLogger: AuditLogger
  ) {}
  
  // Encrypt data with field-level encryption
  async encryptField(
    data: any,
    fieldName: string,
    options: EncryptionOptions = {}
  ): Promise<EncryptedData> {
    try {
      // Get or generate data encryption key
      const dek = await this.keyManager.getDataEncryptionKey(fieldName);
      
      // Generate IV
      const iv = crypto.randomBytes(this.ivLength);
      
      // Create cipher
      const cipher = crypto.createCipheriv(this.algorithm, dek.key, iv);
      
      // Encrypt data
      const encrypted = Buffer.concat([
        cipher.update(JSON.stringify(data), 'utf8'),
        cipher.final()
      ]);
      
      // Get auth tag
      const authTag = cipher.getAuthTag();
      
      // Create encrypted data object
      const encryptedData: EncryptedData = {
        ciphertext: encrypted.toString('base64'),
        iv: iv.toString('base64'),
        authTag: authTag.toString('base64'),
        keyId: dek.keyId,
        algorithm: this.algorithm,
        timestamp: new Date()
      };
      
      // Audit log
      await this.auditLogger.logEncryption({
        fieldName,
        keyId: dek.keyId,
        algorithm: this.algorithm,
        dataSize: encrypted.length
      });
      
      return encryptedData;
    } catch (error) {
      await this.auditLogger.logEncryptionFailure({
        fieldName,
        error: error.message
      });
      throw new EncryptionError('Failed to encrypt field', error);
    }
  }
  
  // Decrypt data
  async decryptField(
    encryptedData: EncryptedData,
    fieldName: string
  ): Promise<any> {
    try {
      // Get decryption key
      const dek = await this.keyManager.getDataEncryptionKey(
        fieldName,
        encryptedData.keyId
      );
      
      // Create decipher
      const decipher = crypto.createDecipheriv(
        encryptedData.algorithm || this.algorithm,
        dek.key,
        Buffer.from(encryptedData.iv, 'base64')
      );
      
      // Set auth tag
      decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'base64'));
      
      // Decrypt data
      const decrypted = Buffer.concat([
        decipher.update(Buffer.from(encryptedData.ciphertext, 'base64')),
        decipher.final()
      ]);
      
      // Audit log
      await this.auditLogger.logDecryption({
        fieldName,
        keyId: encryptedData.keyId
      });
      
      return JSON.parse(decrypted.toString('utf8'));
    } catch (error) {
      await this.auditLogger.logDecryptionFailure({
        fieldName,
        error: error.message
      });
      throw new DecryptionError('Failed to decrypt field', error);
    }
  }
  
  // Hash passwords with Argon2id
  async hashPassword(password: string): Promise<string> {
    const salt = crypto.randomBytes(this.saltLength);
    
    const hash = await argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 65536, // 64 MiB
      timeCost: 3,
      parallelism: 4,
      salt,
      hashLength: 32
    });
    
    return hash;
  }
  
  // Generate secure tokens
  generateSecureToken(length: number = 32): string {
    return crypto.randomBytes(length).toString('base64url');
  }
  
  // Encrypt file with streaming
  async encryptFile(
    inputPath: string,
    outputPath: string,
    metadata?: any
  ): Promise<FileEncryptionResult> {
    const dek = await this.keyManager.generateDataEncryptionKey();
    const iv = crypto.randomBytes(this.ivLength);
    
    const cipher = crypto.createCipheriv(this.algorithm, dek.key, iv);
    const input = fs.createReadStream(inputPath);
    const output = fs.createWriteStream(outputPath);
    
    return new Promise((resolve, reject) => {
      let processedBytes = 0;
      
      input.on('data', (chunk) => {
        processedBytes += chunk.length;
      });
      
      input.on('error', reject);
      output.on('error', reject);
      
      output.on('finish', () => {
        const authTag = cipher.getAuthTag();
        
        // Write metadata
        const encryptionMetadata = {
          keyId: dek.keyId,
          iv: iv.toString('base64'),
          authTag: authTag.toString('base64'),
          algorithm: this.algorithm,
          originalSize: processedBytes,
          metadata: metadata ? this.encryptMetadata(metadata, dek) : null
        };
        
        fs.writeFileSync(
          `${outputPath}.meta`,
          JSON.stringify(encryptionMetadata)
        );
        
        resolve({
          encryptedPath: outputPath,
          metadataPath: `${outputPath}.meta`,
          size: processedBytes,
          keyId: dek.keyId
        });
      });
      
      input.pipe(cipher).pipe(output);
    });
  }
  
  // Searchable encryption
  async encryptSearchable(
    data: string,
    fieldName: string
  ): Promise<SearchableEncryptedData> {
    // Generate deterministic IV for searchability
    const deterministicIv = this.generateDeterministicIv(data, fieldName);
    
    // Encrypt with deterministic encryption
    const encrypted = await this.encryptField(data, fieldName, {
      iv: deterministicIv,
      deterministic: true
    });
    
    // Generate blind index for range queries
    const blindIndex = await this.generateBlindIndex(data, fieldName);
    
    return {
      ...encrypted,
      blindIndex,
      searchable: true
    };
  }
  
  private generateDeterministicIv(data: string, context: string): Buffer {
    const hash = crypto.createHash('sha256');
    hash.update(data);
    hash.update(context);
    hash.update(this.keyManager.getSearchKey());
    return hash.digest().slice(0, this.ivLength);
  }
  
  private async generateBlindIndex(
    data: string,
    fieldName: string
  ): Promise<string> {
    const hmac = crypto.createHmac('sha256', await this.keyManager.getIndexKey());
    hmac.update(fieldName);
    hmac.update(data.toLowerCase().trim());
    return hmac.digest('base64');
  }
}
```

### Key Management Implementation
```typescript
export class KeyManagementService {
  private keyCache = new Map<string, CachedKey>();
  private rotationSchedule = new Map<string, RotationPolicy>();
  
  constructor(
    private vault: VaultProvider,
    private hsm: HSMProvider,
    private config: KeyManagementConfig
  ) {
    this.initializeKeyRotation();
  }
  
  // Generate new data encryption key
  async generateDataEncryptionKey(): Promise<DataEncryptionKey> {
    // Generate DEK
    const dek = crypto.randomBytes(32); // 256 bits
    const keyId = this.generateKeyId();
    
    // Encrypt DEK with KEK
    const kek = await this.getKeyEncryptionKey();
    const encryptedDek = await this.wrapKey(dek, kek);
    
    // Store encrypted DEK
    await this.vault.store(`dek/${keyId}`, {
      encryptedKey: encryptedDek,
      algorithm: 'AES-256',
      createdAt: new Date(),
      kekId: kek.id,
      status: 'active'
    });
    
    // Cache the key
    this.keyCache.set(keyId, {
      key: dek,
      expiresAt: new Date(Date.now() + this.config.cacheTimeout)
    });
    
    return {
      keyId,
      key: dek,
      algorithm: 'AES-256'
    };
  }
  
  // Get or retrieve data encryption key
  async getDataEncryptionKey(
    context: string,
    keyId?: string
  ): Promise<DataEncryptionKey> {
    // Check cache first
    if (keyId && this.keyCache.has(keyId)) {
      const cached = this.keyCache.get(keyId)!;
      if (cached.expiresAt > new Date()) {
        return { keyId, key: cached.key, algorithm: 'AES-256' };
      }
    }
    
    // Get active key for context
    if (!keyId) {
      keyId = await this.getActiveKeyId(context);
    }
    
    // Retrieve from vault
    const encryptedDek = await this.vault.get(`dek/${keyId}`);
    if (!encryptedDek) {
      throw new KeyNotFoundError(`Key ${keyId} not found`);
    }
    
    // Decrypt DEK with KEK
    const kek = await this.getKeyEncryptionKey(encryptedDek.kekId);
    const dek = await this.unwrapKey(encryptedDek.encryptedKey, kek);
    
    // Cache the key
    this.keyCache.set(keyId, {
      key: dek,
      expiresAt: new Date(Date.now() + this.config.cacheTimeout)
    });
    
    return {
      keyId,
      key: dek,
      algorithm: encryptedDek.algorithm
    };
  }
  
  // Get key encryption key from HSM
  private async getKeyEncryptionKey(kekId?: string): Promise<KeyEncryptionKey> {
    if (!kekId) {
      kekId = await this.getActiveKekId();
    }
    
    // KEKs are stored in HSM
    const kekHandle = await this.hsm.getKeyHandle(kekId);
    
    return {
      id: kekId,
      handle: kekHandle,
      algorithm: 'RSA-OAEP'
    };
  }
  
  // Key rotation
  async rotateKeys(context: string): Promise<void> {
    const policy = this.rotationSchedule.get(context);
    if (!policy || !this.shouldRotate(policy)) {
      return;
    }
    
    // Generate new key
    const newKey = await this.generateDataEncryptionKey();
    
    // Update active key mapping
    await this.vault.store(`active-key/${context}`, {
      keyId: newKey.keyId,
      rotatedAt: new Date(),
      previousKeyId: policy.currentKeyId
    });
    
    // Re-encrypt data in background
    this.scheduleReEncryption(context, policy.currentKeyId, newKey.keyId);
    
    // Update rotation policy
    policy.lastRotation = new Date();
    policy.currentKeyId = newKey.keyId;
  }
  
  // Emergency key recovery
  async recoverKey(
    keyId: string,
    approvals: KeyRecoveryApproval[]
  ): Promise<DataEncryptionKey> {
    // Verify approvals
    if (approvals.length < this.config.minRecoveryApprovals) {
      throw new InsufficientApprovalsError();
    }
    
    // Verify each approval signature
    for (const approval of approvals) {
      const valid = await this.verifyApproval(approval);
      if (!valid) {
        throw new InvalidApprovalError();
      }
    }
    
    // Retrieve key shares from escrow
    const shares = await Promise.all(
      approvals.map(a => this.vault.getEscrowShare(keyId, a.userId))
    );
    
    // Reconstruct key using Shamir's Secret Sharing
    const key = this.reconstructKey(shares);
    
    // Audit log
    await this.auditLogger.logKeyRecovery({
      keyId,
      approvers: approvals.map(a => a.userId),
      timestamp: new Date()
    });
    
    return {
      keyId,
      key,
      algorithm: 'AES-256'
    };
  }
  
  // HSM operations
  private async wrapKey(dek: Buffer, kek: KeyEncryptionKey): Promise<string> {
    return this.hsm.wrapKey(dek, kek.handle, {
      algorithm: 'RSA-OAEP',
      hash: 'SHA-256',
      label: Buffer.from('DEK')
    });
  }
  
  private async unwrapKey(wrapped: string, kek: KeyEncryptionKey): Promise<Buffer> {
    return this.hsm.unwrapKey(wrapped, kek.handle, {
      algorithm: 'RSA-OAEP',
      hash: 'SHA-256',
      label: Buffer.from('DEK')
    });
  }
  
  // Key destruction
  async destroyKey(keyId: string, reason: string): Promise<void> {
    // Mark key as destroyed in vault
    await this.vault.update(`dek/${keyId}`, {
      status: 'destroyed',
      destroyedAt: new Date(),
      destroyedBy: this.getCurrentUser(),
      reason
    });
    
    // Remove from cache
    this.keyCache.delete(keyId);
    
    // Cryptographic erasure from HSM if applicable
    if (await this.hsm.hasKey(keyId)) {
      await this.hsm.destroyKey(keyId);
    }
    
    // Audit log
    await this.auditLogger.logKeyDestruction({
      keyId,
      reason,
      timestamp: new Date()
    });
  }
}

// HashiCorp Vault provider
export class VaultProvider {
  private client: any; // Vault client
  
  constructor(private config: VaultConfig) {
    this.client = vault({
      endpoint: config.endpoint,
      token: config.token
    });
  }
  
  async store(path: string, data: any): Promise<void> {
    await this.client.write(path, {
      data,
      options: {
        cas: 0 // Check-and-set
      }
    });
  }
  
  async get(path: string): Promise<any> {
    const response = await this.client.read(path);
    return response?.data?.data;
  }
  
  // Enable transit engine for encryption
  async enableTransitEngine(): Promise<void> {
    await this.client.mount('transit', {
      type: 'transit',
      description: 'Transit secret engine for encryption'
    });
    
    // Create encryption keys
    await this.createTransitKey('admin-panel-kek', {
      type: 'rsa-4096',
      autoRotatePeriod: '90d'
    });
  }
  
  // Encrypt data using transit engine
  async transitEncrypt(keyName: string, plaintext: string): Promise<string> {
    const response = await this.client.write(`transit/encrypt/${keyName}`, {
      plaintext: Buffer.from(plaintext).toString('base64')
    });
    return response.data.ciphertext;
  }
}
```

### React Encryption Components
```tsx
import React, { createContext, useContext, useState, useEffect, useRef } from 'react';

interface EncryptionContextValue {
  encrypt: (data: any, options?: EncryptOptions) => Promise<string>;
  decrypt: (encryptedData: string) => Promise<any>;
  encryptFile: (file: File) => Promise<EncryptedFile>;
  generateKey: () => Promise<CryptoKey>;
  isEncrypted: (data: any) => boolean;
}

const EncryptionContext = createContext<EncryptionContextValue | undefined>(undefined);

// Encryption provider
export const EncryptionProvider: React.FC<{ children: React.ReactNode }> = ({
  children
}) => {
  const [keyPair, setKeyPair] = useState<CryptoKeyPair | null>(null);
  const workerRef = useRef<Worker | null>(null);
  
  useEffect(() => {
    // Initialize Web Worker for encryption operations
    workerRef.current = new Worker('/encryption.worker.js');
    
    // Generate key pair
    initializeKeys();
    
    return () => {
      workerRef.current?.terminate();
    };
  }, []);
  
  const initializeKeys = async () => {
    try {
      // Generate RSA key pair for key exchange
      const kp = await crypto.subtle.generateKey(
        {
          name: 'RSA-OAEP',
          modulusLength: 4096,
          publicExponent: new Uint8Array([1, 0, 1]),
          hash: 'SHA-256'
        },
        true,
        ['encrypt', 'decrypt']
      );
      
      setKeyPair(kp);
      
      // Export public key for server
      const publicKey = await crypto.subtle.exportKey('spki', kp.publicKey);
      await sendPublicKeyToServer(publicKey);
    } catch (error) {
      console.error('Failed to initialize encryption keys:', error);
    }
  };
  
  const encrypt = async (data: any, options?: EncryptOptions): Promise<string> => {
    // Generate AES key for data encryption
    const aesKey = await crypto.subtle.generateKey(
      {
        name: 'AES-GCM',
        length: 256
      },
      true,
      ['encrypt']
    );
    
    // Encrypt data
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const encodedData = new TextEncoder().encode(JSON.stringify(data));
    
    const encryptedData = await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv
      },
      aesKey,
      encodedData
    );
    
    // Encrypt AES key with recipient's public key
    const exportedAesKey = await crypto.subtle.exportKey('raw', aesKey);
    const encryptedKey = await crypto.subtle.encrypt(
      {
        name: 'RSA-OAEP'
      },
      options?.recipientPublicKey || keyPair!.publicKey,
      exportedAesKey
    );
    
    // Combine encrypted key, IV, and data
    const combined = {
      key: btoa(String.fromCharCode(...new Uint8Array(encryptedKey))),
      iv: btoa(String.fromCharCode(...iv)),
      data: btoa(String.fromCharCode(...new Uint8Array(encryptedData))),
      timestamp: Date.now()
    };
    
    return btoa(JSON.stringify(combined));
  };
  
  const decrypt = async (encryptedData: string): Promise<any> => {
    try {
      const combined = JSON.parse(atob(encryptedData));
      
      // Decrypt AES key
      const encryptedKey = Uint8Array.from(atob(combined.key), c => c.charCodeAt(0));
      const aesKeyData = await crypto.subtle.decrypt(
        {
          name: 'RSA-OAEP'
        },
        keyPair!.privateKey,
        encryptedKey
      );
      
      // Import AES key
      const aesKey = await crypto.subtle.importKey(
        'raw',
        aesKeyData,
        'AES-GCM',
        false,
        ['decrypt']
      );
      
      // Decrypt data
      const iv = Uint8Array.from(atob(combined.iv), c => c.charCodeAt(0));
      const ciphertext = Uint8Array.from(atob(combined.data), c => c.charCodeAt(0));
      
      const decryptedData = await crypto.subtle.decrypt(
        {
          name: 'AES-GCM',
          iv
        },
        aesKey,
        ciphertext
      );
      
      const decoded = new TextDecoder().decode(decryptedData);
      return JSON.parse(decoded);
    } catch (error) {
      console.error('Decryption failed:', error);
      throw new Error('Failed to decrypt data');
    }
  };
  
  const encryptFile = async (file: File): Promise<EncryptedFile> => {
    return new Promise((resolve, reject) => {
      const worker = workerRef.current;
      if (!worker) {
        reject(new Error('Encryption worker not available'));
        return;
      }
      
      const messageId = crypto.randomUUID();
      
      const handleMessage = (event: MessageEvent) => {
        if (event.data.id === messageId) {
          worker.removeEventListener('message', handleMessage);
          
          if (event.data.error) {
            reject(new Error(event.data.error));
          } else {
            resolve(event.data.result);
          }
        }
      };
      
      worker.addEventListener('message', handleMessage);
      worker.postMessage({
        id: messageId,
        action: 'encryptFile',
        file,
        publicKey: keyPair?.publicKey
      });
    });
  };
  
  const generateKey = async (): Promise<CryptoKey> => {
    return crypto.subtle.generateKey(
      {
        name: 'AES-GCM',
        length: 256
      },
      true,
      ['encrypt', 'decrypt']
    );
  };
  
  const isEncrypted = (data: any): boolean => {
    if (typeof data !== 'string') return false;
    
    try {
      const decoded = atob(data);
      const parsed = JSON.parse(decoded);
      return !!(parsed.key && parsed.iv && parsed.data);
    } catch {
      return false;
    }
  };
  
  return (
    <EncryptionContext.Provider
      value={{
        encrypt,
        decrypt,
        encryptFile,
        generateKey,
        isEncrypted
      }}
    >
      {children}
    </EncryptionContext.Provider>
  );
};

// Encryption hook
export const useEncryption = () => {
  const context = useContext(EncryptionContext);
  if (!context) {
    throw new Error('useEncryption must be used within EncryptionProvider');
  }
  return context;
};

// Secure form component
export const SecureForm: React.FC<{
  onSubmit: (data: any) => void;
  fields: FormField[];
}> = ({ onSubmit, fields }) => {
  const { encrypt } = useEncryption();
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [encrypting, setEncrypting] = useState(false);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setEncrypting(true);
    
    try {
      // Encrypt sensitive fields
      const encryptedData: Record<string, any> = {};
      
      for (const field of fields) {
        if (field.encrypted && formData[field.name]) {
          encryptedData[field.name] = await encrypt(formData[field.name]);
        } else {
          encryptedData[field.name] = formData[field.name];
        }
      }
      
      onSubmit(encryptedData);
    } catch (error) {
      console.error('Form encryption failed:', error);
    } finally {
      setEncrypting(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {fields.map(field => (
        <div key={field.name} className="form-field">
          <label>
            {field.label}
            {field.encrypted && (
              <span className="encryption-indicator" title="This field will be encrypted">
                🔒
              </span>
            )}
          </label>
          
          {field.type === 'password' ? (
            <PasswordInput
              value={formData[field.name] || ''}
              onChange={(value) => setFormData({ ...formData, [field.name]: value })}
              {...field.props}
            />
          ) : (
            <input
              type={field.type || 'text'}
              value={formData[field.name] || ''}
              onChange={(e) => setFormData({ ...formData, [field.name]: e.target.value })}
              {...field.props}
            />
          )}
        </div>
      ))}
      
      <button type="submit" disabled={encrypting}>
        {encrypting ? 'Encrypting...' : 'Submit'}
      </button>
    </form>
  );
};

// Secure storage hook
export const useSecureStorage = () => {
  const { encrypt, decrypt } = useEncryption();
  
  const setItem = async (key: string, value: any): Promise<void> => {
    const encrypted = await encrypt(value);
    localStorage.setItem(`secure_${key}`, encrypted);
  };
  
  const getItem = async (key: string): Promise<any> => {
    const encrypted = localStorage.getItem(`secure_${key}`);
    if (!encrypted) return null;
    
    try {
      return await decrypt(encrypted);
    } catch (error) {
      console.error('Failed to decrypt stored item:', error);
      return null;
    }
  };
  
  const removeItem = (key: string): void => {
    localStorage.removeItem(`secure_${key}`);
  };
  
  const clear = (): void => {
    const keys = Object.keys(localStorage);
    keys.forEach(key => {
      if (key.startsWith('secure_')) {
        localStorage.removeItem(key);
      }
    });
  };
  
  return { setItem, getItem, removeItem, clear };
};

// Encrypted state hook
export const useEncryptedState = <T>(
  initialValue: T,
  storageKey?: string
) => {
  const { encrypt, decrypt } = useEncryption();
  const { setItem, getItem } = useSecureStorage();
  const [value, setValue] = useState<T>(initialValue);
  const [loading, setLoading] = useState(false);
  
  // Load from secure storage on mount
  useEffect(() => {
    if (storageKey) {
      setLoading(true);
      getItem(storageKey)
        .then(stored => {
          if (stored !== null) {
            setValue(stored);
          }
        })
        .finally(() => setLoading(false));
    }
  }, [storageKey]);
  
  const setEncryptedValue = async (newValue: T) => {
    setValue(newValue);
    
    if (storageKey) {
      await setItem(storageKey, newValue);
    }
  };
  
  return [value, setEncryptedValue, loading] as const;
};
```

### Vue.js Encryption Implementation
```vue
<template>
  <div>
    <slot />
  </div>
</template>

<script setup lang="ts">
import { provide, ref, onMounted } from 'vue';
import type { EncryptionConfig } from '@/types/encryption';

// Encryption state
const keyPair = ref<CryptoKeyPair | null>(null);
const isInitialized = ref(false);

// Initialize encryption
const initializeEncryption = async () => {
  try {
    // Generate RSA key pair
    const kp = await crypto.subtle.generateKey(
      {
        name: 'RSA-OAEP',
        modulusLength: 4096,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: 'SHA-256'
      },
      true,
      ['encrypt', 'decrypt']
    );
    
    keyPair.value = kp;
    isInitialized.value = true;
    
    // Export and send public key to server
    const publicKey = await crypto.subtle.exportKey('spki', kp.publicKey);
    await sendPublicKeyToServer(publicKey);
  } catch (error) {
    console.error('Failed to initialize encryption:', error);
  }
};

// Encrypt data
const encrypt = async (data: any, options?: EncryptOptions): Promise<string> => {
  if (!keyPair.value) {
    throw new Error('Encryption not initialized');
  }
  
  // Generate AES key
  const aesKey = await crypto.subtle.generateKey(
    {
      name: 'AES-GCM',
      length: 256
    },
    true,
    ['encrypt']
  );
  
  // Encrypt data
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encodedData = new TextEncoder().encode(JSON.stringify(data));
  
  const encryptedData = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv
    },
    aesKey,
    encodedData
  );
  
  // Encrypt AES key
  const exportedAesKey = await crypto.subtle.exportKey('raw', aesKey);
  const encryptedKey = await crypto.subtle.encrypt(
    {
      name: 'RSA-OAEP'
    },
    options?.recipientPublicKey || keyPair.value.publicKey,
    exportedAesKey
  );
  
  // Combine and encode
  const combined = {
    key: btoa(String.fromCharCode(...new Uint8Array(encryptedKey))),
    iv: btoa(String.fromCharCode(...iv)),
    data: btoa(String.fromCharCode(...new Uint8Array(encryptedData))),
    timestamp: Date.now()
  };
  
  return btoa(JSON.stringify(combined));
};

// Decrypt data
const decrypt = async (encryptedData: string): Promise<any> => {
  if (!keyPair.value) {
    throw new Error('Encryption not initialized');
  }
  
  try {
    const combined = JSON.parse(atob(encryptedData));
    
    // Decrypt AES key
    const encryptedKey = Uint8Array.from(atob(combined.key), c => c.charCodeAt(0));
    const aesKeyData = await crypto.subtle.decrypt(
      {
        name: 'RSA-OAEP'
      },
      keyPair.value.privateKey,
      encryptedKey
    );
    
    // Import AES key
    const aesKey = await crypto.subtle.importKey(
      'raw',
      aesKeyData,
      'AES-GCM',
      false,
      ['decrypt']
    );
    
    // Decrypt data
    const iv = Uint8Array.from(atob(combined.iv), c => c.charCodeAt(0));
    const ciphertext = Uint8Array.from(atob(combined.data), c => c.charCodeAt(0));
    
    const decryptedData = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv
      },
      aesKey,
      ciphertext
    );
    
    const decoded = new TextDecoder().decode(decryptedData);
    return JSON.parse(decoded);
  } catch (error) {
    console.error('Decryption failed:', error);
    throw new Error('Failed to decrypt data');
  }
};

// Provide encryption functions
provide('encryption', {
  encrypt,
  decrypt,
  isInitialized,
  keyPair
});

// Initialize on mount
onMounted(() => {
  initializeEncryption();
});
</script>

<!-- Encryption composable -->
<script lang="ts">
import { inject, ref } from 'vue';

export function useEncryption() {
  const encryption = inject('encryption');
  if (!encryption) {
    throw new Error('useEncryption must be used within EncryptionProvider');
  }
  return encryption;
}

// Secure storage composable
export function useSecureStorage() {
  const { encrypt, decrypt } = useEncryption();
  
  const setItem = async (key: string, value: any): Promise<void> => {
    const encrypted = await encrypt(value);
    localStorage.setItem(`secure_${key}`, encrypted);
  };
  
  const getItem = async (key: string): Promise<any> => {
    const encrypted = localStorage.getItem(`secure_${key}`);
    if (!encrypted) return null;
    
    try {
      return await decrypt(encrypted);
    } catch (error) {
      console.error('Failed to decrypt stored item:', error);
      return null;
    }
  };
  
  const removeItem = (key: string): void => {
    localStorage.removeItem(`secure_${key}`);
  };
  
  return { setItem, getItem, removeItem };
}

// Encrypted ref
export function useEncryptedRef<T>(initialValue: T, storageKey?: string) {
  const value = ref<T>(initialValue);
  const { setItem, getItem } = useSecureStorage();
  
  // Load from storage
  if (storageKey) {
    getItem(storageKey).then(stored => {
      if (stored !== null) {
        value.value = stored;
      }
    });
  }
  
  // Watch for changes and save
  watch(value, async (newValue) => {
    if (storageKey) {
      await setItem(storageKey, newValue);
    }
  }, { deep: true });
  
  return value;
}
</script>

<!-- Secure form component -->
<template>
  <form @submit.prevent="handleSubmit">
    <div v-for="field in fields" :key="field.name" class="form-field">
      <label>
        {{ field.label }}
        <span v-if="field.encrypted" class="encryption-indicator" title="Encrypted">
          🔒
        </span>
      </label>
      
      <component
        :is="getFieldComponent(field)"
        v-model="formData[field.name]"
        v-bind="field.props"
        :type="field.type"
      />
    </div>
    
    <button type="submit" :disabled="encrypting">
      {{ encrypting ? 'Encrypting...' : 'Submit' }}
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { useEncryption } from '@/composables/useEncryption';

interface Props {
  fields: FormField[];
  onSubmit: (data: any) => void;
}

const props = defineProps<Props>();
const { encrypt } = useEncryption();

const formData = reactive<Record<string, any>>({});
const encrypting = ref(false);

const handleSubmit = async () => {
  encrypting.value = true;
  
  try {
    const encryptedData: Record<string, any> = {};
    
    for (const field of props.fields) {
      if (field.encrypted && formData[field.name]) {
        encryptedData[field.name] = await encrypt(formData[field.name]);
      } else {
        encryptedData[field.name] = formData[field.name];
      }
    }
    
    props.onSubmit(encryptedData);
  } catch (error) {
    console.error('Form encryption failed:', error);
  } finally {
    encrypting.value = false;
  }
};

const getFieldComponent = (field: FormField) => {
  switch (field.type) {
    case 'password':
      return 'PasswordInput';
    case 'textarea':
      return 'textarea';
    case 'select':
      return 'select';
    default:
      return 'input';
  }
};
</script>

<!-- Encryption directive -->
<script lang="ts">
import { Directive } from 'vue';
import { useEncryption } from '@/composables/useEncryption';

export const vEncrypt: Directive = {
  mounted(el, binding) {
    const { encrypt } = useEncryption();
    
    const handleEncrypt = async () => {
      const value = el.value || el.textContent;
      if (value) {
        const encrypted = await encrypt(value);
        if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
          el.value = encrypted;
        } else {
          el.textContent = encrypted;
        }
      }
    };
    
    if (binding.modifiers.blur) {
      el.addEventListener('blur', handleEncrypt);
    } else if (binding.modifiers.change) {
      el.addEventListener('change', handleEncrypt);
    } else {
      handleEncrypt();
    }
  }
};

export const vSecure: Directive = {
  mounted(el, binding) {
    const { decrypt } = useEncryption();
    
    const handleDecrypt = async () => {
      const encrypted = el.dataset.encrypted || binding.value;
      if (encrypted) {
        try {
          const decrypted = await decrypt(encrypted);
          el.textContent = decrypted;
        } catch (error) {
          el.textContent = '[Decryption Failed]';
        }
      }
    };
    
    if (binding.modifiers.lazy) {
      const observer = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          handleDecrypt();
          observer.disconnect();
        }
      });
      observer.observe(el);
    } else {
      handleDecrypt();
    }
  }
};
</script>
```

### Database Encryption
```typescript
// PostgreSQL encryption with pgcrypto
export class PostgreSQLEncryption {
  async setupEncryption(db: any): Promise<void> {
    // Enable pgcrypto extension
    await db.query('CREATE EXTENSION IF NOT EXISTS pgcrypto');
    
    // Create encryption functions
    await db.query(`
      CREATE OR REPLACE FUNCTION encrypt_field(
        plaintext TEXT,
        key_id TEXT
      ) RETURNS JSONB AS $$
      DECLARE
        encryption_key BYTEA;
        iv BYTEA;
        ciphertext TEXT;
      BEGIN
        -- Get encryption key
        SELECT decode(key_data, 'base64') INTO encryption_key
        FROM encryption_keys
        WHERE id = key_id AND status = 'active';
        
        -- Generate IV
        iv := gen_random_bytes(16);
        
        -- Encrypt
        ciphertext := encode(
          encrypt_iv(
            plaintext::BYTEA,
            encryption_key,
            iv,
            'aes-cbc'
          ),
          'base64'
        );
        
        RETURN jsonb_build_object(
          'ciphertext', ciphertext,
          'iv', encode(iv, 'base64'),
          'key_id', key_id,
          'algorithm', 'aes-256-cbc',
          'timestamp', NOW()
        );
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER;
      
      CREATE OR REPLACE FUNCTION decrypt_field(
        encrypted_data JSONB
      ) RETURNS TEXT AS $$
      DECLARE
        encryption_key BYTEA;
        plaintext TEXT;
      BEGIN
        -- Get decryption key
        SELECT decode(key_data, 'base64') INTO encryption_key
        FROM encryption_keys
        WHERE id = encrypted_data->>'key_id';
        
        -- Decrypt
        plaintext := convert_from(
          decrypt_iv(
            decode(encrypted_data->>'ciphertext', 'base64'),
            encryption_key,
            decode(encrypted_data->>'iv', 'base64'),
            'aes-cbc'
          ),
          'UTF8'
        );
        
        RETURN plaintext;
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER;
    `);
    
    // Create transparent encryption trigger
    await db.query(`
      CREATE OR REPLACE FUNCTION transparent_encryption_trigger()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Encrypt sensitive fields
        IF NEW.ssn IS NOT NULL THEN
          NEW.ssn_encrypted = encrypt_field(NEW.ssn, 'current_key_id');
          NEW.ssn = NULL;
        END IF;
        
        IF NEW.credit_card IS NOT NULL THEN
          NEW.credit_card_encrypted = encrypt_field(NEW.credit_card, 'current_key_id');
          NEW.credit_card = NULL;
        END IF;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);
  }
  
  // Column-level encryption
  async encryptColumn(
    table: string,
    column: string,
    keyId: string
  ): Promise<void> {
    await db.query(`
      -- Add encrypted column
      ALTER TABLE ${table} ADD COLUMN ${column}_encrypted JSONB;
      
      -- Encrypt existing data
      UPDATE ${table}
      SET ${column}_encrypted = encrypt_field(${column}::TEXT, $1)
      WHERE ${column} IS NOT NULL;
      
      -- Drop original column
      ALTER TABLE ${table} DROP COLUMN ${column};
      
      -- Rename encrypted column
      ALTER TABLE ${table} RENAME COLUMN ${column}_encrypted TO ${column};
    `, [keyId]);
  }
}

// MongoDB field-level encryption
export class MongoDBEncryption {
  private keyVault: Collection;
  private kmsProviders: any;
  
  async setupEncryption(client: MongoClient): Promise<void> {
    // Setup key vault
    this.keyVault = client.db('encryption').collection('__keyVault');
    
    // Create unique index on key vault
    await this.keyVault.createIndex(
      { keyAltNames: 1 },
      {
        unique: true,
        partialFilterExpression: {
          keyAltNames: { $exists: true }
        }
      }
    );
    
    // Configure KMS providers
    this.kmsProviders = {
      aws: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      },
      local: {
        key: Buffer.from(process.env.LOCAL_MASTER_KEY, 'base64')
      }
    };
  }
  
  // Create encrypted collection
  async createEncryptedCollection(
    db: Db,
    collectionName: string,
    schema: any
  ): Promise<void> {
    // Generate data encryption key
    const dataKey = await this.createDataKey('aws', {
      masterKey: {
        region: 'us-east-1',
        key: process.env.AWS_KMS_KEY_ARN
      }
    });
    
    // Create JSON schema with encryption
    const encryptedSchema = {
      bsonType: 'object',
      encryptMetadata: {
        keyId: [dataKey]
      },
      properties: {
        ssn: {
          encrypt: {
            bsonType: 'string',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
          }
        },
        creditCard: {
          encrypt: {
            bsonType: 'string',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
          }
        },
        medicalRecords: {
          encrypt: {
            bsonType: 'object',
            algorithm: 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
          }
        }
      }
    };
    
    // Create collection with schema validation
    await db.createCollection(collectionName, {
      validator: { $jsonSchema: encryptedSchema }
    });
  }
  
  // Get auto-encryption client
  getEncryptedClient(connectionString: string): MongoClient {
    const schemaMap = this.getSchemaMap();
    
    return new MongoClient(connectionString, {
      autoEncryption: {
        keyVaultNamespace: 'encryption.__keyVault',
        kmsProviders: this.kmsProviders,
        schemaMap
      }
    });
  }
}

// Redis encryption wrapper
export class RedisEncryption {
  constructor(
    private redis: Redis,
    private encryptionService: EncryptionService
  ) {}
  
  async setEncrypted(key: string, value: any, ttl?: number): Promise<void> {
    const encrypted = await this.encryptionService.encryptField(value, key);
    const serialized = JSON.stringify(encrypted);
    
    if (ttl) {
      await this.redis.setex(key, ttl, serialized);
    } else {
      await this.redis.set(key, serialized);
    }
  }
  
  async getEncrypted(key: string): Promise<any> {
    const serialized = await this.redis.get(key);
    if (!serialized) return null;
    
    const encrypted = JSON.parse(serialized);
    return this.encryptionService.decryptField(encrypted, key);
  }
  
  // Encrypted hash operations
  async hsetEncrypted(
    key: string,
    field: string,
    value: any
  ): Promise<void> {
    const encrypted = await this.encryptionService.encryptField(value, `${key}:${field}`);
    await this.redis.hset(key, field, JSON.stringify(encrypted));
  }
  
  async hgetEncrypted(key: string, field: string): Promise<any> {
    const serialized = await this.redis.hget(key, field);
    if (!serialized) return null;
    
    const encrypted = JSON.parse(serialized);
    return this.encryptionService.decryptField(encrypted, `${key}:${field}`);
  }
}
```

### Compliance Configuration
```typescript
// Complete encryption configuration
export const encryptionConfig: EncryptionConfiguration = {
  // Algorithm settings
  algorithms: {
    symmetric: {
      default: 'AES-256-GCM',
      allowed: ['AES-256-GCM', 'AES-256-CBC', 'ChaCha20-Poly1305'],
      keyRotation: 90 // days
    },
    asymmetric: {
      default: 'RSA-4096',
      allowed: ['RSA-4096', 'ECC-P384', 'Ed25519'],
      keyRotation: 365 // days
    },
    hashing: {
      passwords: 'argon2id',
      general: 'BLAKE3',
      legacy: 'SHA-256'
    }
  },
  
  // Compliance requirements
  compliance: {
    gdpr: {
      enabled: true,
      requireEncryption: ['email', 'name', 'address', 'phone'],
      pseudonymization: true,
      rightToErasure: true
    },
    
    hipaa: {
      enabled: true,
      phi: ['diagnosis', 'treatment', 'medication', 'medical_history'],
      minimumKeyLength: 256,
      auditAllAccess: true
    },
    
    pciDss: {
      enabled: true,
      cardData: {
        storage: 'prohibited',
        tokenization: true,
        transmission: 'TLS-1.3'
      },
      keyManagement: 'HSM'
    },
    
    fips: {
      enabled: true,
      level: 2,
      approvedAlgorithms: ['AES-256', 'RSA-3072', 'SHA-256'],
      hardwareRequired: true
    }
  },
  
  // Key management
  keyManagement: {
    provider: 'aws-kms',
    hsm: {
      enabled: true,
      type: 'CloudHSM',
      partition: 'admin-panel'
    },
    rotation: {
      automatic: true,
      frequency: 90,
      graceperiod: 30
    },
    escrow: {
      enabled: true,
      shares: 5,
      threshold: 3
    }
  },
  
  // Performance settings
  performance: {
    caching: {
      enabled: true,
      ttl: 3600,
      maxSize: 1000
    },
    parallelization: {
      enabled: true,
      workers: 4,
      batchSize: 100
    },
    hardwareAcceleration: {
      aesni: true,
      gpu: false
    }
  },
  
  // Security policies
  policies: {
    minimumKeyLength: 256,
    enforceEncryption: true,
    allowDowngrade: false,
    quantumSafe: {
      enabled: true,
      algorithms: ['CRYSTALS-Kyber', 'CRYSTALS-Dilithium'],
      migration: '2025-01-01'
    }
  }
};

// Crypto-agility implementation
export class CryptoAgilityManager {
  private algorithms = new Map<string, CryptoAlgorithm>();
  private versions = new Map<string, number>();
  
  registerAlgorithm(
    name: string,
    algorithm: CryptoAlgorithm,
    version: number = 1
  ): void {
    this.algorithms.set(`${name}_v${version}`, algorithm);
    this.versions.set(name, version);
  }
  
  async encrypt(
    data: any,
    algorithmHint?: string
  ): Promise<VersionedEncryptedData> {
    // Select best algorithm based on data type and size
    const algorithm = this.selectAlgorithm(data, algorithmHint);
    const version = this.versions.get(algorithm.name) || 1;
    
    const encrypted = await algorithm.encrypt(data);
    
    return {
      ...encrypted,
      algorithm: algorithm.name,
      version,
      timestamp: new Date()
    };
  }
  
  async decrypt(data: VersionedEncryptedData): Promise<any> {
    const algorithmKey = `${data.algorithm}_v${data.version}`;
    const algorithm = this.algorithms.get(algorithmKey);
    
    if (!algorithm) {
      // Try to handle legacy algorithms
      const legacy = this.getLegacyAlgorithm(data.algorithm, data.version);
      if (legacy) {
        return legacy.decrypt(data);
      }
      
      throw new Error(`Unknown algorithm: ${algorithmKey}`);
    }
    
    return algorithm.decrypt(data);
  }
  
  private selectAlgorithm(data: any, hint?: string): CryptoAlgorithm {
    if (hint && this.algorithms.has(hint)) {
      return this.algorithms.get(hint)!;
    }
    
    // Select based on data characteristics
    const dataSize = JSON.stringify(data).length;
    
    if (dataSize > 1_000_000) {
      // Use stream cipher for large data
      return this.algorithms.get('ChaCha20-Poly1305_v1')!;
    } else if (typeof data === 'object' && data.searchable) {
      // Use deterministic encryption for searchable data
      return this.algorithms.get('AES-256-SIV_v1')!;
    } else {
      // Default to AES-GCM
      return this.algorithms.get('AES-256-GCM_v1')!;
    }
  }
}
```

## Integration Points
- Receives field classifications from Schema Analyzer
- Coordinates with Access Control Manager for key permissions
- Works with Audit Logger for cryptographic operations tracking
- Integrates with Compliance Checker for regulatory requirements
- Provides encryption services to all other agents

## Best Practices
1. Never store encryption keys with encrypted data
2. Use HSM for master key protection
3. Implement key rotation policies
4. Enable audit logging for all crypto operations
5. Use authenticated encryption modes (GCM, CCM)
6. Implement proper key escrow procedures
7. Test key recovery processes regularly
8. Monitor for weak encryption usage
9. Prepare for quantum-resistant algorithms
10. Maintain crypto-agility for future migrations