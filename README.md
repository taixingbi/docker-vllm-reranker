# docker-vllm-reranker

Runs [vLLM](https://github.com/vllm-project/vllm)’s OpenAI-compatible HTTP API in Docker for **`BAAI/bge-reranker-v2-m3`** using **`--runner pooling`** and **`--convert classify`** (the supported way to serve this cross-encoder / reranker architecture in pooling mode). Listens on **`8002`**, with **`--dtype half`** (fp16) and **`--gpu-memory-utilization` default `0.01`**. Override with **`VLLM_GPU_MEMORY_UTILIZATION`** in `.env` or Compose if you need more GPU headroom.

See vLLM [pooling / scoring](https://docs.vllm.ai/en/latest/models/pooling_models/scoring/) for request shapes and behavior.

## Publish image (GitHub Actions)

On push to `main` or manual **workflow_dispatch**, [.github/workflows/docker-push.yml](.github/workflows/docker-push.yml) builds the [Dockerfile](Dockerfile) and pushes:

- `taixingbi/docker-vllm-reranker-v1:latest`
- `taixingbi/docker-vllm-reranker-v1:<git_sha>`

Secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (for CI; the public image is under **`taixingbi`** on Docker Hub).

## Pull image and run (Docker CLI)

Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) so `--gpus all` works.

```bash
docker pull taixingbi/docker-vllm-reranker-v1:latest

docker rm -f vllm_reranker

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

Follow logs for that container (`--name vllm_reranker`):

```bash
docker logs -f vllm_reranker
```

The image [Dockerfile](Dockerfile) sets **`--model`**, **`--runner pooling`**, **`--convert classify`**, **`--host 0.0.0.0`**, **`--port 8002`**, **`--dtype half`**, **`--max-model-len 512`**, and **`--gpu-memory-utilization 0.01`**. Arguments after the image name **replace** the default `CMD`; to tune flags without a full override, use [Compose](#local-or-gpu-host-compose).

**Upstream-equivalent** (same vLLM flags as this image; add `--host 0.0.0.0 --port 8002` if you map host `8002` to container `8002`):

```bash
docker run -d \
  --name vllm_reranker \
  --gpus all \
  --ipc host \
  -p 8002:8002 \
  vllm/vllm-openai:latest \
  --model BAAI/bge-reranker-v2-m3 \
  --runner pooling \
  --convert classify \
  --host 0.0.0.0 \
  --port 8002 \
  --dtype half \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.01
```

### Stop and remove the container

Docker manages containers with **`docker rm`** (not shell **`rm -rf`**, which deletes files on disk). To **stop and delete** the reranker container created above so you can re-run `docker run` with the same `--name`:

```bash
docker rm -f vllm_reranker
```

With Compose, tear down the service (and default network); named volumes like `hf-cache` are **kept** unless you add `-v`:

```bash
docker compose down
```

To also remove the Hugging Face cache volume (deletes downloaded weights):

```bash
docker compose down -v
```

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
| `VLLM_RUNNER` | `--runner` | `pooling` |
| `VLLM_CONVERT` | `--convert` | `classify` |
| `HUGGING_FACE_HUB_TOKEN` | Token if the hub needs auth | _(empty)_ |
| `VLLM_PORT` | `--port` and host port mapping | `8002` |
| `VLLM_DTYPE` | `--dtype` | `half` |
| `VLLM_MAX_MODEL_LEN` | `--max-model-len` | `512` |
| `VLLM_GPU_MEMORY_UTILIZATION` | `--gpu-memory-utilization` | `0.01` |

Weights cache: Compose volume `hf-cache` → `/root/.cache/huggingface`.

**Port mapping:** [docker-compose.yml](docker-compose.yml) uses `${VLLM_PORT:-8002}` on both sides of `ports:` so host and container stay aligned when you change the port.

## Try the API

Health (when exposed by vLLM):

```bash
curl -sS "http://127.0.0.1:8002/health"
```

**Rerank** (`/v1/rerank` — not `/v1/embeddings`):

```bash
curl "http://127.0.0.1:8002/v1/rerank" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "query": "What is Paris?",
    "documents": [
      "Paris is the capital of France.",
      "Berlin is the capital of Germany."
    ],
    "top_n": 2
  }'
```

Use `http://127.0.0.1:8002` as the base URL. If your vLLM version uses a different path or JSON shape, see the [pooling / scoring](https://docs.vllm.ai/en/latest/models/pooling_models/scoring/) docs for that release.
