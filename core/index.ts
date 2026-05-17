import { HermesCore } from './Engine';
import { SecureGateway } from '../interfaces/Gateway';

async function bootstrap() {
    console.log("==========================================");
    console.log("🚀 Starting Hermes-Portable V2 Engine...");
    console.log("==========================================");

    const engine = new HermesCore();
    const gateway = new SecureGateway();

    // Setup an initial secure vault if testing
    gateway.encryptAndStore('my-super-secret-password', {
        telegramToken: '12345:ABCDEF',
        discordToken: 'MTEw.Gz12.XYZ',
        geminiApiKey: 'AIzaSyD...'
    });

    gateway.on('command', async (event) => {
        await engine.executeTaskLoop(event.message, event.rawPayload);
    });

    gateway.startPolling();

    process.on('SIGINT', () => {
        console.log("\n[Core] Shutting down Hermes-Portable V2 Engine gracefully.");
        process.exit(0);
    });
}

bootstrap();
