import { EventEmitter } from 'events';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

export interface MessengerEvent {
    channel: 'telegram' | 'discord';
    userId: string;
    message: string;
    timestamp: number;
    rawPayload: any;
}

export class SecureGateway extends EventEmitter {
    private vaultPath: string;
    private rootPath: string;

    constructor() {
        super();
        this.rootPath = process.cwd();
        this.vaultPath = path.join(this.rootPath, 'data', 'secure.vault');
    }

    /**
     * Derive AES-256-GCM Key from system UUID and user password
     */
    private deriveKey(password: string, salt: Buffer): Buffer {
        // In a real implementation, system UUID would be fetched via OS libraries
        const machineUUID = "LOCAL-MACHINE-UUID-STUB"; 
        const material = `${machineUUID}:${password}`;
        return crypto.pbkdf2Sync(material, salt, 100000, 32, 'sha256');
    }

    /**
     * Store secrets securely
     */
    public encryptAndStore(password: string, secrets: any) {
        try {
            const salt = crypto.randomBytes(16);
            const iv = crypto.randomBytes(12);
            const key = this.deriveKey(password, salt);
            
            const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
            let encrypted = cipher.update(JSON.stringify(secrets), 'utf8', 'hex');
            encrypted += cipher.final('hex');
            const authTag = cipher.getAuthTag();

            const vaultData = {
                salt: salt.toString('hex'),
                iv: iv.toString('hex'),
                authTag: authTag.toString('hex'),
                data: encrypted
            };

            // Atomic transaction
            const tempPath = path.join(this.rootPath, '.tmp', 'secure.vault.tmp');
            fs.mkdirSync(path.dirname(tempPath), { recursive: true });
            fs.writeFileSync(tempPath, JSON.stringify(vaultData, null, 2));
            fs.renameSync(tempPath, this.vaultPath);
            
            console.log(`[Gateway] Secure vault updated.`);
        } catch (err) {
            console.error(`[Gateway] Failed to encrypt vault:`, err);
        }
    }

    /**
     * Read and decrypt secrets
     */
    public decryptVault(password: string): any {
        if (!fs.existsSync(this.vaultPath)) return null;

        try {
            const vaultData = JSON.parse(fs.readFileSync(this.vaultPath, 'utf8'));
            const salt = Buffer.from(vaultData.salt, 'hex');
            const iv = Buffer.from(vaultData.iv, 'hex');
            const authTag = Buffer.from(vaultData.authTag, 'hex');
            const key = this.deriveKey(password, salt);

            const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
            decipher.setAuthTag(authTag);
            let decrypted = decipher.update(vaultData.data, 'hex', 'utf8');
            decrypted += decipher.final('utf8');
            
            return JSON.parse(decrypted);
        } catch (err) {
            console.error(`[Gateway] Vault decryption failed (Wrong password?):`, (err as Error).message);
            return null;
        }
    }

    /**
     * Start Telegram/Discord polling using Secure Vault credentials
     */
    public async startPolling(password: string) {
        console.log(`[Gateway] Decrypting Secure Vault...`);
        const credentials = this.decryptVault(password);
        
        if (!credentials) {
            console.error(`[Gateway] ❌ Failed to start polling. Invalid password or missing vault.`);
            return;
        }

        console.log(`[Gateway] Listening for Telegram / Discord Webhooks & Polling...`);

        // Initialize Telegram
        if (credentials.telegramToken) {
            const { Bot } = require('grammy');
            const bot = new Bot(credentials.telegramToken);
            bot.on('message:text', (ctx: any) => {
                this.emitMessage({
                    channel: 'telegram',
                    userId: ctx.from.id.toString(),
                    message: ctx.message.text,
                    timestamp: Date.now(),
                    rawPayload: ctx.message
                });
            });
            bot.start().catch((err: any) => console.error('[Gateway] Telegram Error:', err));
            console.log(`[Gateway] ✅ Telegram Bot polling started.`);
        }

        // Initialize Discord
        if (credentials.discordToken) {
            const { Client, GatewayIntentBits } = require('discord.js');
            const client = new Client({
                intents: [
                    GatewayIntentBits.Guilds,
                    GatewayIntentBits.GuildMessages,
                    GatewayIntentBits.MessageContent
                ]
            });

            client.on('messageCreate', (message: any) => {
                if (message.author.bot) return;
                this.emitMessage({
                    channel: 'discord',
                    userId: message.author.id,
                    message: message.content,
                    timestamp: message.createdTimestamp,
                    rawPayload: message
                });
            });

            client.login(credentials.discordToken).catch((err: any) => console.error('[Gateway] Discord Error:', err));
            client.on('ready', () => console.log(`[Gateway] ✅ Discord Bot polling started.`));
        }
    }

    private emitMessage(event: MessengerEvent) {
        console.log(`[Gateway] Message received from [${event.channel}]: ${event.message}`);
        this.emit('command', event);
    }
}
