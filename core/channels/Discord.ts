import { Client, GatewayIntentBits } from 'discord.js';
import { eventBridge } from './EventBridge';

export class DiscordService {
    private client: Client;

    constructor(token: string) {
        this.client = new Client({
            intents: [
                GatewayIntentBits.Guilds,
                GatewayIntentBits.GuildMessages,
                GatewayIntentBits.MessageContent
            ]
        });

        this.client.on('ready', () => {
            console.log(`[DiscordService] Logged in as ${this.client.user?.tag}!`);
        });

        this.client.on('messageCreate', (message) => {
            if (message.author.bot) return;

            eventBridge.emitMessage({
                channel: 'discord',
                userId: message.author.id,
                message: message.content,
                timestamp: message.createdTimestamp,
                rawPayload: message
            });
        });

        this.client.login(token).catch(err => {
            console.error('[DiscordService] Error logging in:', err);
        });
    }

    public stop() {
        console.log('[DiscordService] Destroying Discord client...');
        this.client.destroy();
    }
}
