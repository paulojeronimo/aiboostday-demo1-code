/** @type {import('next').NextConfig} */
const isDev = process.env.NODE_ENV === 'development';

const rawBasePath = process.env.NEXT_PUBLIC_BASE_PATH || '';
const normalizedBasePath = rawBasePath
  ? `/${rawBasePath.replace(/^\/+|\/+$/g, '')}`
  : '';

const nextConfig = {
  // Keep server features (API routes) in dev; only export static output in prod builds.
  output: isDev ? undefined : 'export',
  basePath: !isDev && normalizedBasePath ? normalizedBasePath : undefined,
  assetPrefix: !isDev && normalizedBasePath ? normalizedBasePath : undefined,
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
