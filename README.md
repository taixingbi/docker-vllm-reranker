# docker-vllm-reranker

Runs [vLLM](https://github.com/vllm-project/vllm)’s OpenAI-compatible HTTP API in Docker for **cross-encoder scoring / reranking**, default model **`BAAI/bge-reranker-v2-m3`**, listening on **`8002`**, with **`--task score`**, **`--dtype half`** (fp16), and **`--gpu-memory-utilization` default `0.15`**.

## Publish image (GitHub Actions)

On push to `main` or manual **workflow_dispatch**, [.github/workflows/docker-push.yml](.github/workflows/docker-push.yml) builds the [Dockerfile](Dockerfile) and pushes:

- `taixingbi/docker-vllm-reranker-v1:latest`
- `taixingbi/docker-vllm-reranker-v1:<git_sha>`

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (for CI; the public image is under **`taixingbi`** on Docker Hub).

## Pull image and run (Docker CLI)

Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) so `--gpus all` works.

```bash
docker pull taixingbi/docker-vllm-reranker-v1:latest

docker run -d \
  --name vllm_reranker \
  --restart unless-stopped \
  --gpus all \
  --ipc host \
  -p 8002:8002 \
  -v hf-cache:/root/.cache/huggingface \
  -e HUGGING_FACE_HUB_TOKEN \
  taixingbi/docker-vllm-reranker-v1:latest
```

The image [Dockerfile](Dockerfile) already sets `--model`, `--task score`, `--port 8002`, `--dtype half`, and related flags. Anything you append after the image name **replaces** the default `CMD` (you would need to pass the full vLLM argument list yourself). To change the model or flags without rebuilding, prefer [Compose](#local-or-gpu-host-compose) and the env vars in the table below.

## Local or GPU host (Compose)

Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

```bash
docker compose up -d
docker compose logs -f vllm_reranker
```

### Environment (optional `.env`)

| Variable | Role | Default |
|----------|------|---------|
| `RERANK_MODEL` | Hugging Face model id for `--model` | `BAAI/bge-reranker-v2-m3` |
| `EMBED_MODEL` | Legacy alias: used only if `RERANK_MODEL` is unset | _(see compose)_ |
| `VLLM_TASK` | vLLM `--task` (this image expects **`score`** for `/v1/score`) | `score` |
| `HUGGING_FACE_HUB_TOKEN` | Token if the hub needs auth | _(empty)_ |
| `VLLM_PORT` | `--port` and host port mapping | `8002` |
| `VLLM_DTYPE` | `--dtype` | `half` |
| `VLLM_MAX_MODEL_LEN` | `--max-model-len` | `512` |
| `VLLM_MAX_NUM_SEQS` | `--max-num-seqs` | `64` |
| `VLLM_GPU_MEMORY_UTILIZATION` | `--gpu-memory-utilization` | `0.15` |

Weights cache: Compose volume `hf-cache` → `/root/.cache/huggingface`.

**Port mapping:** [docker-compose.yml](docker-compose.yml) uses `${VLLM_PORT:-8002}` on both sides of `ports:` so host and container stay aligned when you change the port.

## Try the API

Health (when exposed by vLLM):

```bash
curl -sS "http://127.0.0.1:8002/health"
```

**Score / rerank** (pairs of texts — not `/v1/embeddings`):

```bash
curl "http://127.0.0.1:8002/v1/score" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "pairs": [
      {"text_1": "What is Paris?", "text_2": "Paris is the capital of France."}
    ]
  }'
```

Use `http://127.0.0.1:8002` as the base URL for clients calling this vLLM server. Request shapes follow your vLLM version’s OpenAI-compatible extensions for scoring.
