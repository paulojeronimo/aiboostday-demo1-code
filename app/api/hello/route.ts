import os from 'os';
import { NextRequest, NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

let callCount = 0;

function corsHeaders(request: NextRequest) {
  const configured = process.env.API_ALLOWED_ORIGINS;
  const allowToken = configured && configured.trim() !== '' ? configured.trim() : '*';

  const allowAll = allowToken === '*';
  const allowedList = allowAll
    ? []
    : allowToken
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);

  const requestOrigin = request.headers.get('origin');
  let originToAllow = allowAll ? '*' : '';

  if (!allowAll && requestOrigin && allowedList.includes(requestOrigin)) {
    originToAllow = requestOrigin;
  }

  const headers = new Headers();
  if (originToAllow) headers.set('Access-Control-Allow-Origin', originToAllow);
  headers.set('Access-Control-Allow-Methods', 'GET,OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type');
  headers.set('Access-Control-Allow-Credentials', 'true');
  return headers;
}

export async function GET(request: NextRequest) {
  const headers = corsHeaders(request);
  const now = new Date().toISOString();
  const hostname = process.env.HOSTNAME || os.hostname();
  const count = ++callCount;

  return NextResponse.json({
    message: `Hello from ${hostname} at ${now}. Call #${count}.`,
    ts: now,
  }, { headers });
}

export async function OPTIONS(request: NextRequest) {
  const headers = corsHeaders(request);
  return new NextResponse(null, { status: 204, headers });
}
