import { EventEmitter } from 'events';

export interface MessengerEvent {
    channel: 'telegram' | 'discord';
    userId: string;
    message: string;
    timestamp: number;
    rawPayload: any;
}

export class EventBridge extends EventEmitter {
    constructor() {
        super();
    }

    public emitMessage(event: MessengerEvent) {
        // Translates raw inputs into structured JSON commands for Hermes Engine
        const structuredCommand = {
            id: `${event.channel}-${event.userId}-${Date.now()}`,
            instruction: event.message,
            payload: event.rawPayload
        };
        
        console.log(`[EventBridge] Received message from ${event.channel}: ${event.message}`);
        this.emit('command', structuredCommand);
    }
}

// Singleton instance to be shared across channels and the engine
export const eventBridge = new EventBridge();
