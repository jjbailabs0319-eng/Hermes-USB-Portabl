import { Bot } from 'grammy';
import { eventBridge } from './EventBridge';

export class TelegramService {
    private bot: Bot;

    constructor(token: string) {
        this.bot = new Bot(token);
        
        this.bot.on('message:text', (ctx) => {
            eventBridge.emitMessage({
                channel: 'telegram',
                userId: ctx.from.id.toString(),
                message: ctx.message.text,
                timestamp: Date.now(),
                rawPayload: ctx.message
            });
        });
    }

    public async start() {
        console.log('[TelegramService] Starting Telegram polling...');
        // bot.start() is asynchronous but runs continuously
        this.bot.start().catch(err => {
            console.error('[TelegramService] Error starting bot:', err);
        });
    }

    public async stop() {
        console.log('[TelegramService] Stopping Telegram polling...');
        await this.bot.stop();
    }
}
