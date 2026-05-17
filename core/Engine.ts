import * as fs from 'fs';
import * as path from 'path';

export interface SkillDocument {
    id: string;
    sequence: string[];
    metric: number;
}

export interface MemoryVector {
    id: string;
    text: string;
    vector: number[];
}

export class HermesCore {
    private rootPath: string;
    private memoryPath: string;
    private memoryCache: MemoryVector[] = [];

    constructor() {
        this.rootPath = process.cwd();
        this.memoryPath = path.join(this.rootPath, 'data', 'memory.json');
        this.loadMemoryMap();
    }

    /**
     * A. Carmack-Inspired Memory Flat-File
     * Read the memory map into host RAM once at startup.
     */
    private loadMemoryMap() {
        if (fs.existsSync(this.memoryPath)) {
            try {
                this.memoryCache = JSON.parse(fs.readFileSync(this.memoryPath, 'utf-8'));
                console.log(`[HermesCore] Loaded ${this.memoryCache.length} memory vectors into RAM.`);
            } catch (err) {
                console.error(`[HermesCore] Error parsing memory.json:`, err);
                this.memoryCache = [];
            }
        } else {
            console.log(`[HermesCore] No memory.json found. Starting fresh.`);
            // Ensure data directory exists
            fs.mkdirSync(path.join(this.rootPath, 'data'), { recursive: true });
            this.syncMemory();
        }
    }

    private syncMemory() {
        // Atomic write for memory.json
        const tempPath = path.join(this.rootPath, '.tmp', 'memory.tmp');
        fs.mkdirSync(path.dirname(tempPath), { recursive: true });
        fs.writeFileSync(tempPath, JSON.stringify(this.memoryCache, null, 2));
        fs.renameSync(tempPath, this.memoryPath);
    }

    /**
     * Lightweight Cosine-Similarity Calculation
     */
    public calculateSimilarity(vecA: number[], vecB: number[]): number {
        let dotProduct = 0, normA = 0, normB = 0;
        for (let i = 0; i < vecA.length; i++) {
            dotProduct += vecA[i] * vecB[i];
            normA += vecA[i] ** 2;
            normB += vecB[i] ** 2;
        }
        if (normA === 0 || normB === 0) return 0;
        return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
    }

    /**
     * B. Torvalds-Inspired Self-Evolution & Skill Storage
     * Atomic transactional mechanism to prevent data corruption.
     */
    public saveSkillAtomic(skillId: string, sequence: string[]) {
        const skill: SkillDocument = { id: skillId, sequence, metric: 1.0 };
        const skillsDir = path.join(this.rootPath, 'core', 'skills');
        fs.mkdirSync(skillsDir, { recursive: true });

        const finalPath = path.join(skillsDir, `${skillId}.json`);
        const tempPath = path.join(this.rootPath, '.tmp', `${skillId}.tmp`);

        try {
            fs.writeFileSync(tempPath, JSON.stringify(skill, null, 2));
            fs.renameSync(tempPath, finalPath);
            console.log(`[HermesCore] 🧬 Skill securely evolved and saved: ${skillId}`);
        } catch (error) {
            console.error(`[HermesCore] ❌ Failed atomic write transaction for skill ${skillId}:`, error);
        }
    }

    /**
     * Hermes Evolutionary Sequence
     */
    public async executeTaskLoop(taskInput: string, payload?: any) {
        console.log(`\n---`);
        console.log(`[HermesCore] 1. Task Parsing: Analysing instruction -> "${taskInput}"`);
        
        // Mock semantic search in RAM
        const mockVec = [1, 0, 0];
        let bestMatch = null;
        let bestScore = -1;
        for (const mem of this.memoryCache) {
            const score = this.calculateSimilarity(mockVec, mem.vector);
            if (score > bestScore) {
                bestScore = score;
                bestMatch = mem;
            }
        }
        if (bestMatch) {
            console.log(`[HermesCore]    -> Found historical semantic match: [Score: ${bestScore.toFixed(2)}] "${bestMatch.text}"`);
        }

        console.log(`[HermesCore] 2. Action Loop: Executing dynamic plan...`);
        // Mock Execution Steps
        const executionPlan = ['fetch_data', 'process_text', 'format_output'];
        
        console.log(`[HermesCore] 3. Self-Critique: Evaluating performance and API latency...`);
        const isSuccessful = true; // Simulated success

        if (isSuccessful) {
            console.log(`[HermesCore] 4. Optimization: Task succeeded. Extracting skill blueprint...`);
            const skillId = `skill_${Date.now()}`;
            this.saveSkillAtomic(skillId, executionPlan);

            // Record into memory cache
            this.memoryCache.push({
                id: `mem_${Date.now()}`,
                text: taskInput,
                vector: [Math.random(), Math.random(), Math.random()] // Fake embedding
            });
            this.syncMemory();
        }
    }
}
