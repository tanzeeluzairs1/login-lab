# Launchpad — Node.js login lab

Two separate Node.js services for Tanzeel's Docker → Terraform → EC2 → GitHub Actions → CloudWatch learning project. This stage runs locally. No database, third-party npm packages, AWS resources, or deployment configuration are required yet.

## Requirements
Node.js 24.x and VS Code. Check `node --version` in the VS Code terminal.

## Run on Windows in VS Code
1. Extract this project and open the `login-lab` folder in VS Code.
2. Copy `backend/.env.example` to `backend/.env` using Explorer. Keep `.env.example` as a template. Do the same for `frontend/.env.example` → `frontend/.env`.
3. In one VS Code terminal:

```
cd backend
npm start
```

4. Open a SECOND terminal (leave the backend running):

```
cd frontend
npm start
```

5. Open http://localhost:3000 (use this exact hostname; 127.0.0.1 is a different browser origin).
6. Local demo email: `tanzeel@example.com`. Local demo password: `LocalLab-ChangeMe123!`.
7. Try a wrong password, then the correct one. Refresh while signed in, then sign out.
8. Stop each server with Ctrl+C.

There is no npm install step: this project uses only Node.js built-in modules. `npm start` loads the .env in that service's directory.

## How requests travel
Browser → frontend Node server on port 3000 → /api proxy → backend on port 5000.
The browser always uses relative `/api` URLs. The frontend server forwards API requests, so there is no separate CORS setup. The backend checks the Origin on state-changing requests.

- `GET /api/health`: backend health (no login required).
- `POST /api/login`: JSON email/password, returns an HttpOnly session cookie.
- `GET /api/me`: current user; 401 without a valid session.
- `POST /api/logout`: invalidates session and clears cookie.

The login page lives in frontend/public/index.html. styles.css controls appearance; app.js submits credentials and updates the UI. backend/server.js verifies credentials and manages sessions. frontend/server.js serves static files and proxies the API.

## Configuration
Backend: PORT, HOST, APP_ORIGIN, DEMO_EMAIL, DEMO_PASSWORD, COOKIE_SECURE.
Frontend: PORT, HOST, BACKEND_URL.
APP_ORIGIN must exactly match the URL in the browser. Use COOKIE_SECURE=true after HTTPS is configured. Both services bind to loopback for local use. Later Docker configuration must set HOST=0.0.0.0 and BACKEND_URL=http://backend:5000, with only the frontend exposed.

## Scope and limitations
One configured demo account, no registration or password recovery. The password is read from the local environment and hashed in memory using scrypt; .env must not be committed. Sessions expire after one hour, live in backend memory, and are lost on restart. This is intended for one backend process, not load balancing. The demo uses a simple global limit of 20 login requests/minute. Production requires durable identity/session storage, per-client rate limiting and HTTPS. Do not use real credentials over HTTP or expose this local configuration publicly.

Backend writes structured JSON request logs to stdout with method, known route, status and duration; it does not log credentials, request bodies or cookies. These are ready to route to CloudWatch when we containerize.

## Next stage
Verify this app locally first. Then add Dockerfiles and Compose, verify container networking, and proceed to Terraform and GitHub Actions. No AWS resources have been created.
