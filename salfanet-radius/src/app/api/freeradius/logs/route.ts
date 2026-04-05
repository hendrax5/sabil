import { NextResponse } from 'next/server';
import { spawn } from 'child_process';
import fs from 'fs';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

// Log file path
const LOG_FILE = '/var/log/freeradius/radius.log'; // Adjust for your system

export async function GET(req: Request) {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const { searchParams } = new URL(req.url);
    const lines = parseInt(searchParams.get('lines') || '50', 10);

    // Create promises for exec (Docker Logs version)
    const readLogs = () => new Promise<string>((resolve, reject) => {
        const tail = spawn('docker', ['logs', '--tail', lines.toString(), 'freeradius']);
        let output = '';
        let error = '';

        tail.stdout.on('data', (data: Buffer) => {
            output += data.toString();
        });

        // Docker logs write to stderr for all daemon messages typically, we should capture them both
        tail.stderr.on('data', (data: Buffer) => {
            output += data.toString();
        });

        tail.on('close', (code: number | null) => {
            if (code === 0 || code === null) {
                resolve(output);
            } else {
                reject(new Error(error || `Docker logs process exited with code ${code}`));
            }
        });
    });

    try {
        const logs = await readLogs();
        return NextResponse.json({
            success: true,
            logs
        });
    } catch (error: any) {
        return NextResponse.json(
            { success: false, error: error.message },
            { status: 500 }
        );
    }
}
