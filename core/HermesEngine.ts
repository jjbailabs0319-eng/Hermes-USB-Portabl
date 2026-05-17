import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
import { EventEmitter } from 'events';

// Types
interface TaskInput { id: string; instruction: string; payload?: any; }
interface ExecutionLog { taskId: string; plan: any; result: any; success: boolean; tokensUsed: number; }
interface SkillDocument { skillName: string; pattern: any; performanceScore: number; }

export class HermesEngine extends EventEmitter {
    private basePath: string;
    private memoryPaths: { episodic: string; semantic: string; context: string; skills: string };
    
    // AES-256-GCM Master Key (In production, load securely from environment/portable setup)
    private vaultKey: Buffer;

    constructor() {
        super();
        // A. OS-Agnostic Portable Storage Layer: 절대경로 추적
        this.basePath = process.cwd(); 
        this.memoryPaths = {
            episodic: path.join(this.basePath, 'data', 'episodic'),
            semantic: path.join(this.basePath, 'data', 'semantic'),
            context: path.join(this.basePath, 'data', 'context'),
            skills: path.join(this.basePath, 'core', 'skills')
        };
        // Generate a temporary execution key (Mocked for demonstration)
        this.vaultKey = crypto.randomBytes(32); 
    }

    /**
     * Bootstraps the directories and engine state.
     */
    public async initialize(): Promise<void> {
        for (const dir of Object.values(this.memoryPaths)) {
            await fs.mkdir(dir, { recursive: true });
        }
        console.log(`[HermesEngine] Initialized at portable path: ${this.basePath}`);
    }

    /**
     * 1. Loading encrypted user credentials securely (Semantic Memory)
     */
    public async loadSecureCredentials(keyName: string): Promise<any> {
        const filePath = path.join(this.memoryPaths.semantic, `${keyName}.vault`);
        try {
            const rawData = await fs.readFile(filePath, 'utf-8');
            const { iv, authTag, encrypted } = JSON.parse(rawData);
            
            const decipher = crypto.createDecipheriv('aes-256-gcm', this.vaultKey, Buffer.from(iv, 'hex'));
            decipher.setAuthTag(Buffer.from(authTag, 'hex'));
            
            let decrypted = decipher.update(encrypted, 'hex', 'utf8');
            decrypted += decipher.final('utf8');
            return JSON.parse(decrypted);
        } catch (error) {
            console.warn(`[HermesEngine] Secure vault not found or inaccessible for: ${keyName}`);
            return null;
        }
    }

    /**
     * 3. Semantic lookup: Searches historical episodic memory / Skills before API requests
     */
    public async lookupSkillOrMemory(task: TaskInput): Promise<SkillDocument | null> {
        try {
            const files = await fs.readdir(this.memoryPaths.skills);
            for (const file of files) {
                if (file.endsWith('.json') && file.includes(task.id.split('-')[0])) {
                    const skillData = await fs.readFile(path.join(this.memoryPaths.skills, file), 'utf-8');
                    return JSON.parse(skillData) as SkillDocument;
                }
            }
        } catch (err) {
            // Handle file lock or absence smoothly
        }
        return null;
    }

    /**
     * 2. Self-Evaluation & Evolutionary Learning
     * Analyzes execution logs and generates a Skill Document if efficient.
     */
    public async evaluateAndLearn(log: ExecutionLog): Promise<void> {
        if (!log.success) {
            console.log(`[HermesEngine] Task ${log.taskId} failed. Skipping learning phase.`);
            return;
        }

        console.log(`[HermesEngine] Auditing Task ${log.taskId} (Tokens Used: ${log.tokensUsed})...`);

        // Hypothetical AI evaluation check for efficiency
        const isOptimalPattern = log.tokensUsed < 1500; // Arbitrary metric for Token Cost Ratio

        if (isOptimalPattern) {
            const newSkill: SkillDocument = {
                skillName: `Skill_${log.taskId}_${Date.now()}`,
                pattern: log.plan,
                performanceScore: 100 - (log.tokensUsed / 100) // Simple dynamic score
            };

            const skillPath = path.join(this.memoryPaths.skills, `${newSkill.skillName}.json`);
            
            try {
                await fs.writeFile(skillPath, JSON.stringify(newSkill, null, 2));
                console.log(`[HermesEngine] 🧬 Evolution Triggered: Extracted new Skill to ${skillPath}`);
            } catch (err) {
                console.error(`[HermesEngine] Failed to write Skill Document:`, err);
            }
        }

        // Save raw episodic memory regardless
        const episodicPath = path.join(this.memoryPaths.episodic, `Log_${log.taskId}.json`);
        await fs.writeFile(episodicPath, JSON.stringify(log, null, 2)).catch(e => console.error(e));
    }
}
