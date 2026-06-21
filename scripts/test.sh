#!/usr/bin/env bash
#
# test.sh — 通过 port-forward 验证应用功能
# 前提:集群里 fastapi 已部署
# 用法:./scripts/test.sh
#

set -euo pipefail

LOCAL_PORT="8001"          # 本地端口(避开被占用的 8000)
SVC="svc/fastapi"
SVC_PORT="8000"

echo "==> 在后台启动 port-forward (${LOCAL_PORT} -> ${SVC_PORT})"
kubectl port-forward "${SVC}" "${LOCAL_PORT}:${SVC_PORT}" >/dev/null 2>&1 &
PF_PID=$!     # 记下后台进程的 PID,结束时好关掉

# --- 确保脚本退出时一定关掉 port-forward,无论成功失败 ---
cleanup() {
  echo "==> 清理:关闭 port-forward (PID ${PF_PID})"
  kill "${PF_PID}" 2>/dev/null || true
}
trap cleanup EXIT

# 轮询等待 port-forward 真正可用(最多 ~15 秒)
echo "==> 等待 port-forward 就绪..."
for i in $(seq 1 15); do
  if curl -s -o /dev/null "http://localhost:${LOCAL_PORT}/"; then
    break
  fi
  sleep 1
done

BASE="http://localhost:${LOCAL_PORT}"

echo ""
echo "==> 测试 / (根路径)"
curl -s "${BASE}/" ; echo ""

echo ""
echo "==> 测试 /health (应为 healthy)"
curl -s "${BASE}/health" ; echo ""

echo ""
echo "==> 测试 /count 三次(数字应递增)"
curl -s "${BASE}/count" ; echo ""
curl -s "${BASE}/count" ; echo ""
curl -s "${BASE}/count" ; echo ""

echo ""
echo "==> 测试完成。"
# trap 会在这里自动触发 cleanup,关掉 port-forward