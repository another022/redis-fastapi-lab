# 用官方 slim 镜像:体积小,但带完整 Python。
FROM python:3.12-slim

# 设置工作目录,容器内后续命令都在这里执行
WORKDIR /app

# --- 关键:先拷依赖文件,再拷代码 ---
# Docker 按层缓存。只要 requirements.txt 不变,
# 下面的 pip install 层就会命中缓存,改 app.py 不会触发重装依赖。
COPY requirements.txt .

# --no-cache-dir:不在镜像里留 pip 缓存,镜像更小
RUN pip install --no-cache-dir -r requirements.txt

# 再拷应用代码
COPY app.py .

# 声明容器监听的端口(文档作用,不会真的开端口)
EXPOSE 8000

# 容器启动时运行的命令。
# 注意没有 --reload:生产环境不需要热重载。
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]