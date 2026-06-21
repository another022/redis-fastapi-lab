import os
import redis
from fastapi import FastAPI
from fastapi.responses import JSONResponse

# --- config: all read from env ---
# 这一点很关键:K8s 里我们会用 ConfigMap / Secret 注入这些值,
# 代码本身不需要任何改动。这就是"配置与代码分离"。
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD", None)

app = FastAPI(title="Redis FastAPI Lab")

# --- Redis 客户端 ---
# decode_responses=True 让返回值是字符串而不是 bytes,省去手动解码
def get_redis_client():
    return redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        password=REDIS_PASSWORD,
        decode_responses=True,
        socket_connect_timeout=2,
    )


@app.get("/")
def root():
    return {"message": "Redis FastAPI Lab is running"}


@app.get("/count")
def count():
    """Every visit make count +1 and return the current value."""
    try:
        r = get_redis_client()
        value = r.incr("visit_count")
        return {"visit_count": value}
    except redis.exceptions.RedisError as e:
        return JSONResponse(
            status_code=503,
            content={"error": "Redis unavailable", "detail": str(e)},
        )


@app.get("/health")
def health():
    """
    Health check: not only check if the process is alive, but also confirm that Redis can be connected.
    The liveness/readiness probes in Stage 16 will use this endpoint.
    """
    try:
        r = get_redis_client()
        r.ping()
        return {"status": "healthy", "redis": "connected"}
    except redis.exceptions.RedisError:
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "redis": "disconnected"},
        )