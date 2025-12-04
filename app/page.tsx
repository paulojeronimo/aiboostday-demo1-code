'use client';

import { useState } from 'react';

export default function HomePage() {
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const appEnv = process.env.NEXT_PUBLIC_APP_ENV || process.env.NODE_ENV || 'local';
  const commitHash = process.env.NEXT_PUBLIC_APP_COMMIT || 'unknown';

  async function callApi() {
    try {
      setLoading(true);
      setMessage(null);
      setError(null);

      const apiBaseUrl =
        process.env.NEXT_PUBLIC_API_BASE_URL?.replace(/\/$/, '') || '';
      const endpoint = apiBaseUrl ? `${apiBaseUrl}/hello` : '/api/hello';

      const res = await fetch(endpoint);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      const data = await res.json();
      setMessage(data.message);
    } catch (err) {
      console.error(err);
      setMessage('Error calling API');
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main style={{ padding: '2rem', fontFamily: 'system-ui, sans-serif' }}>
      <h1 style={{ textAlign: 'center' }}>
        <u>AI Boost Day</u>
      </h1>
      <h3 style={{ textAlign: 'center', marginTop: '0.5rem' }}>
        <a href="https://www.linkedin.com/in/paulojeronimo/" target="_blank" rel="noreferrer">
          by Paulo Jerônimo
        </a>
      </h3>
      <h2>Demo #1: Next.js app</h2>
      <p style={{ marginTop: '0.25rem' }}>
        <a
          href="https://github.com/paulojeronimo/aiboostday-demo1-code"
          target="_blank"
          rel="noreferrer"
        >
          github.com/paulojeronimo/aiboostday-demo1-code
        </a>
      </p>
      <p>This is a straightforward SPA calling a backend API.</p>
      <p>
        Environment: <strong>{appEnv}</strong>
      </p>
      <p>
        Commit: <strong>{commitHash}</strong>
      </p>
      <button onClick={callApi} disabled={loading}>
        {loading ? 'Calling API...' : 'Call API (/hello)'}
      </button>
      {message && (
        <p style={{ marginTop: '1rem' }}>
          API response: <strong>{message}</strong>
        </p>
      )}

      {error && (
        <p style={{ marginTop: '0.5rem', color: 'red' }}>
          Details: <strong>{error}</strong>
        </p>
      )}

      <hr style={{ margin: '2rem 0' }} />
      <h1 style={{ textAlign: 'center', fontSize: '2em', lineHeight: 1.2 }}>
        Event pre-registration:
      </h1>
      <h2 style={{ textAlign: 'center', fontSize: '2em', lineHeight: 1.3 }}>
        <a
          href="https://wa.me/5561998073864?text=.aiboostday"
          target="_blank"
          rel="noreferrer"
        >
          Send your name and email to my WhatsApp Bot
        </a>
      </h2>
      <div style={{ textAlign: 'center', marginTop: '1rem' }}>
        <img
          src="https://api.qrserver.com/v1/create-qr-code/?size=280x280&data=https%3A%2F%2Fwa.me%2F5561998073864%3Ftext%3D.aiboostday"
          alt="QR code to open WhatsApp with message .aiboostday"
          style={{ width: '280px', height: '280px' }}
        />
      </div>
    </main>
  );
}
