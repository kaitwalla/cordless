<p align="center">
  <img src="app/assets/images/cordless-icon.png" alt="Cordless" width="128" height="108">
</p>

<h1 align="center">Cordless</h1>

<p align="center">
  A self-hosted team chat application with audio/video calls
</p>

---

Cordless is a web-based chat application. It supports many of the features you'd
expect, including:

- Multiple rooms, with access controls
- Direct messages
- Audio/video calls with screen sharing
- File attachments with previews
- Search
- Notifications (via Web Push)
- @mentions
- API, with support for bot integrations

## Deploying with Docker

Cordless's Docker image contains everything needed for a fully-functional,
single-machine deployment. This includes the web app, background jobs, caching,
file serving, and SSL.

### Quick Start (Development)

For local development and testing:

```bash
# Clone the repository
git clone https://github.com/yourusername/cordless.git
cd cordless

# Copy environment file and generate secrets
cp .env.example .env
openssl rand -hex 64 >> .env  # Add as SECRET_KEY_BASE

# Start all services
docker compose up
```

The app will be available at http://localhost:3000

### Production Deployment

For production, use `docker-compose.production.yml` which includes:
- Redis with authentication
- LiveKit server for video calls
- SSL via Let's Encrypt
- Persistent storage volumes
- Health checks and auto-restart

#### 1. Create Environment File

Create a `.env` file with your production configuration:

```bash
# Required - generate with: openssl rand -hex 64
SECRET_KEY_BASE=your_secret_key_here

# Required - generate with: openssl rand -hex 32
REDIS_PASSWORD=your_redis_password_here

# Required for video calls - generate unique values
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret

# Required for SSL (or set DISABLE_SSL=true)
SSL_DOMAIN=chat.yourdomain.com

# Required for push notifications
# Generate with: bundle exec rake vapid:generate
VAPID_PUBLIC_KEY=your_vapid_public_key
VAPID_PRIVATE_KEY=your_vapid_private_key

# Optional - S3 storage (defaults to local storage)
STORAGE_SERVICE=amazon
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
AWS_S3_BUCKET=your-bucket-name

# Optional - Error tracking
SENTRY_DSN=your_sentry_dsn
```

#### 2. Configure LiveKit (Production)

Edit `livekit.yaml` for your production environment. For calls to work behind NAT,
you'll need to configure TURN servers:

```yaml
turn:
  enabled: true
  domain: turn.yourdomain.com
  tls_port: 5349
  udp_port: 3478
  external_tls: true
```

See [LiveKit Self-Hosting Guide](https://docs.livekit.io/realtime/self-hosting/deployment/) for details.

#### 3. Deploy

```bash
# Build the image
docker compose -f docker-compose.production.yml build

# Start all services
docker compose -f docker-compose.production.yml up -d

# View logs
docker compose -f docker-compose.production.yml logs -f
```

#### 4. Firewall Configuration

Ensure these ports are open:
- **80/443** - HTTP/HTTPS (web app)
- **7880** - LiveKit WebSocket/API
- **7881** - LiveKit TCP (WebRTC fallback)
- **7882/udp** - LiveKit UDP (WebRTC media)

### Alternative: Manual Docker Run

If you prefer not to use docker-compose:

```bash
# Build the image
docker build -t cordless .

# Run with minimal configuration
docker run \
  --publish 80:80 --publish 443:443 \
  --restart unless-stopped \
  --volume cordless:/rails/storage \
  --env SECRET_KEY_BASE=$YOUR_SECRET_KEY_BASE \
  --env VAPID_PUBLIC_KEY=$YOUR_PUBLIC_KEY \
  --env VAPID_PRIVATE_KEY=$YOUR_PRIVATE_KEY \
  --env SSL_DOMAIN=chat.example.com \
  --env LIVEKIT_API_KEY=$YOUR_LIVEKIT_KEY \
  --env LIVEKIT_API_SECRET=$YOUR_LIVEKIT_SECRET \
  --env LIVEKIT_URL=wss://your-livekit-server:7880 \
  cordless
```

Note: This requires a separate LiveKit server and Redis instance.

### Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `SECRET_KEY_BASE` | Yes | Rails secret key (generate with `openssl rand -hex 64`) |
| `REDIS_URL` | No | Redis connection URL (defaults to localhost) |
| `REDIS_PASSWORD` | Prod | Redis password for production |
| `SSL_DOMAIN` | No | Domain for Let's Encrypt SSL certificate |
| `DISABLE_SSL` | No | Set to `true` to serve over plain HTTP |
| `VAPID_PUBLIC_KEY` | No | Web Push public key |
| `VAPID_PRIVATE_KEY` | No | Web Push private key |
| `LIVEKIT_API_KEY` | Prod | LiveKit API key for video calls |
| `LIVEKIT_API_SECRET` | Prod | LiveKit API secret |
| `LIVEKIT_URL` | No | LiveKit server URL (defaults to `ws://localhost:7880`) |
| `STORAGE_SERVICE` | No | `local` or `amazon` for S3 storage |
| `AWS_ACCESS_KEY_ID` | S3 | AWS access key (when using S3) |
| `AWS_SECRET_ACCESS_KEY` | S3 | AWS secret key (when using S3) |
| `AWS_REGION` | No | AWS region (defaults to `us-east-1`) |
| `AWS_S3_BUCKET` | S3 | S3 bucket name |
| `AWS_S3_ENDPOINT` | No | Custom S3 endpoint (for MinIO, DigitalOcean Spaces) |
| `SENTRY_DSN` | No | Sentry error tracking DSN |

### Persistent Storage

Map a volume to `/rails/storage` to persist:
- SQLite database
- Uploaded files (when using local storage)
- ActiveStorage attachments

### Using LiveKit Cloud

Instead of self-hosting LiveKit, you can use [LiveKit Cloud](https://cloud.livekit.io/):

1. Create a LiveKit Cloud project
2. Get your API key and secret from the dashboard
3. Set `LIVEKIT_URL` to your LiveKit Cloud WebSocket URL (e.g., `wss://your-project.livekit.cloud`)

## Running in Development

```bash
bin/setup
bin/dev
```

Or with Docker:

```bash
docker compose up
```

## Worth Noting

When you start Cordless for the first time, you'll be guided through
creating an admin account.
The email address of this admin account will be shown on the login page
so that people who forget their password know who to contact for help.
(You can change this email later in the settings)

Cordless is single-tenant: any rooms designated "public" will be accessible by
all users in the system. To support entirely distinct groups of customers, you
would deploy multiple instances of the application.

## Audio/Video Calls

Cordless includes built-in audio/video calling powered by [LiveKit](https://livekit.io/). Features include:

- **Audio calls** - Join room calls with microphone
- **Video calls** - Enable camera for face-to-face conversations
- **Screen sharing** - Share your screen with other participants
- **Picture-in-Picture** - Draggable call panel stays visible while browsing

To start a call, click the phone icon in any room's navigation bar. Other room
members will see a notification and can join the call.

### LiveKit Configuration

For development, LiveKit runs in dev mode with default credentials. For production:

1. Generate unique API credentials:
   ```bash
   # Generate a random API key
   openssl rand -hex 16

   # Generate a random API secret
   openssl rand -hex 32
   ```

2. Set the environment variables:
   ```bash
   LIVEKIT_API_KEY=your_generated_key
   LIVEKIT_API_SECRET=your_generated_secret
   LIVEKIT_URL=wss://your-livekit-server:7880
   ```

3. For calls to work reliably across different networks, configure TURN servers
   in `livekit.yaml`. See [LiveKit TURN documentation](https://docs.livekit.io/realtime/self-hosting/deployment/#turn-relay).
