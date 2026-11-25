import os
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from pydantic import BaseModel
import psycopg

DATABASE_URL = os.environ["DATABASE_URL"]
SESSION_SECRET = os.environ["SESSION_SECRET"]
DEMO_USER = os.environ.get("PLATFORM_USER", "scc26-student")
DEMO_PASS = os.environ.get("PLATFORM_PASSWORD", "scc26-week3-demo")
TEAM_NAME = os.environ.get("TEAM_NAME", "CHPC SCC26 Team")
PROJECT_SLUG = os.environ.get("PROJECT_SLUG", "collab-agent-scc26")

serializer = URLSafeTimedSerializer(SESSION_SECRET)
START_TIME = time.time()


def get_conn():
    return psycopg.connect(DATABASE_URL, autocommit=True)


def init_db():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    username TEXT PRIMARY KEY,
                    display_name TEXT NOT NULL,
                    team_name TEXT NOT NULL,
                    project_slug TEXT NOT NULL
                );
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS project_notes (
                    id SERIAL PRIMARY KEY,
                    author TEXT NOT NULL,
                    content TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                );
            """)
            cur.execute("""
                INSERT INTO users (username, display_name, team_name, project_slug)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (username) DO NOTHING;
            """, (DEMO_USER, "SCC26 Student Operator", TEAM_NAME, PROJECT_SLUG))


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="SCC26 Student Project Platform", lifespan=lifespan)


class LoginRequest(BaseModel):
    username: str
    password: str


class NoteRequest(BaseModel):
    content: str


def current_user(request: Request) -> str:
    token = request.cookies.get("scc26_session")
    if not token:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        data = serializer.loads(token, max_age=86400)
        return data["u"]
    except (BadSignature, SignatureExpired):
        raise HTTPException(status_code=401, detail="Invalid or expired session")


@app.get("/health")
def health():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
    return {"status": "ok", "database": "connected", "project": PROJECT_SLUG}


@app.get("/metrics")
def metrics():
    uptime = round(time.time() - START_TIME, 2)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM project_notes;")
            notes_count = cur.fetchone()[0]
    body = (
        "# HELP student_platform_up Student Project Platform health status\n"
        "# TYPE student_platform_up gauge\n"
        "student_platform_up 1\n"
        "# HELP student_platform_uptime_seconds Process uptime in seconds\n"
        "# TYPE student_platform_uptime_seconds counter\n"
        f"student_platform_uptime_seconds {uptime}\n"
        "# HELP student_platform_notes_total Persisted project notes in PostgreSQL\n"
        "# TYPE student_platform_notes_total gauge\n"
        f"student_platform_notes_total {notes_count}\n"
    )
    return Response(content=body, media_type="text/plain; version=0.0.4")


@app.post("/api/login")
def login(payload: LoginRequest, response: Response):
    if payload.username != DEMO_USER or payload.password != DEMO_PASS:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = serializer.dumps({"u": payload.username})
    response.set_cookie(
        key="scc26_session",
        value=token,
        httponly=True,
        samesite="lax",
        secure=True,
        max_age=86400,
    )
    return {"authenticated": True, "username": payload.username}


@app.post("/api/logout")
def logout(response: Response):
    response.delete_cookie("scc26_session")
    return {"authenticated": False}


@app.get("/api/me")
def me(request: Request):
    username = current_user(request)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT username, display_name, team_name, project_slug FROM users WHERE username = %s;",
                (username,),
            )
            row = cur.fetchone()
    return {
        "username": row[0],
        "display_name": row[1],
        "team_name": row[2],
        "project_slug": row[3],
    }


@app.get("/api/status")
def status(request: Request):
    current_user(request)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version();")
            pg_ver = cur.fetchone()[0].split(",")[0]
            cur.execute("SELECT id, author, content, created_at FROM project_notes ORDER BY id DESC LIMIT 20;")
            notes = [
                {"id": r[0], "author": r[1], "content": r[2], "created_at": r[3].isoformat()}
                for r in cur.fetchall()
            ]
    return {
        "team_name": TEAM_NAME,
        "project_slug": PROJECT_SLUG,
        "environment": "sebowa-kubernetes",
        "database_engine": pg_ver,
        "observability": "Prometheus + Grafana + Wazuh + Suricata",
        "notes": notes,
    }


@app.post("/api/notes")
def create_note(payload: NoteRequest, request: Request):
    username = current_user(request)
    text = payload.content.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Content cannot be empty")
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO project_notes (author, content) VALUES (%s, %s) RETURNING id, created_at;",
                (username, text),
            )
            row = cur.fetchone()
    return {"id": row[0], "author": username, "content": text, "created_at": row[1].isoformat()}


app.mount("/assets", StaticFiles(directory="/app/frontend"), name="assets")


@app.get("/")
def index():
    return FileResponse("/app/frontend/index.html")
