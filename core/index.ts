import { HermesEngine } from './HermesEngine';
import { eventBridge } from './channels/EventBridge';
// Import these when tokens are available
// import { TelegramService } from './channels/Telegram';
// import { DiscordService } from './channels/Discord';

async function bootstrap() {
    console.log("==========================================");
    console.log("🚀 Starting Hermes-Portable Core Engine...");
    console.log("==========================================");

    const engine = new HermesEngine();
    
    try {
        await engine.initialize();
        console.log("[Core] Engine fully initialized. Waiting for tasks...");

        // Listen for structured commands from the messenger interfaces
        eventBridge.on('command', async (task) => {
            console.log(`[Core] Received Task: ${task.id} -> ${task.instruction}`);
            
            // 1. Semantic Lookup
            const pastSkill = await engine.lookupSkillOrMemory(task);
            if (pastSkill) {
                console.log(`[Core] 🧠 Found reusable skill: ${pastSkill.skillName}`);
            }

            // 2. Execution (Mocked)
            console.log(`[Core] Executing task...`);
            
            // 3. Self-Evaluation & Learning
            const mockLog = {
                taskId: task.id,
                plan: { steps: ["step1", "step2"] },
                result: { status: 'success' },
                success: true,
                tokensUsed: Math.floor(Math.random() * 2000)
            };
            await engine.evaluateAndLearn(mockLog);
        });

        // Initialize Discord/Telegram with credentials securely loaded from semantic memory
        // const creds = await engine.loadSecureCredentials('messengers');
        // if (creds?.telegramToken) new TelegramService(creds.telegramToken).start();
        // if (creds?.discordToken) new DiscordService(creds.discordToken);
        
        process.on('SIGINT', () => {
            console.log("\n[Core] Shutting down Hermes-Portable Engine gracefully.");
            process.exit(0);
        });

    } catch (err) {
        console.error("[Core] Failed to initialize HermesEngine:", err);
        process.exit(1);
    }
}

bootstrap();
