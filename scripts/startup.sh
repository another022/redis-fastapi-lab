#!/usr/bin/env bash
#
# startup.sh — 从镜像构建到部署的一键脚本
# 用法:从项目根目录运行  ./scripts/startup.sh
#

# --- 严格模式:让脚本在出错时立刻停下,而不是带病继续 ---
set -euo pipefail
# -e  任何命令失败立即退出
# -u  使用未定义变量时报错
# -o pipefail  管道中任何一环失败都算失败

# --- 配置变量(集中在顶部,方便改) ---
IMAGE_NAME="redis-fastapi"
IMAGE_TAG="0.1.0"
CLUSTER_NAME="redis-fastapi"
# 项目根目录:脚本所在目录的上一级
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [1/4] 构建 Docker 镜像 ${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "${ROOT_DIR}/app"

echo "==> [2/4] 把镜像加载进 kind 集群 '${CLUSTER_NAME}'"
kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"

echo "==> [3/4] 按依赖顺序 apply Kubernetes 清单"
# 顺序很重要:配置和存储必须先于使用它们的工作负载
kubectl apply -f "${ROOT_DIR}/k8s/redis-configmap.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/redis-secret.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/redis-pvc.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/redis-deployment.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/redis-service.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/fastapi-deployment.yaml"
kubectl apply -f "${ROOT_DIR}/k8s/fastapi-service.yaml"

echo "==> [4/4] 等待 Pod 就绪"
# 等 Redis 真正 Ready,再等 FastAPI。--timeout 防止无限等待。
kubectl wait --for=condition=ready pod -l app=redis --timeout=120s
kubectl wait --for=condition=ready pod -l app=fastapi --timeout=120s

echo ""
echo "==> 部署完成!当前状态:"
kubectl get pods
kubectl get svc

echo ""
echo "==> 用以下命令测试(另开一个终端):"
echo "    kubectl port-forward svc/fastapi 8001:8000"
echo "    然后运行:  ./scripts/test.sh"