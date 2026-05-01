# docker-vllm-reranker

Dockerized [vLLM](https://github.com/vllm-project/vllm) OpenAI-compatible server running on port **8002** with `BAAI/bge-reranker-v2-m3` by default (`--dtype half`, fp16).

## Publish image (GitHub Actions)

On push to `main` or manual **workflow_dispatch**, [.github/workflows/docker-push.yml](.github/workflows/docker-push.yml) builds the [Dockerfile](Dockerfile) and pushes:

- `<dockerhub_user>/docker-vllm-reranker-v1:latest`
- `<dockerhub_user>/docker-vllm-reranker-v1:<git_sha>`

Repository secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.

## Local or GPU host (Compose)

Requires [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

```bash
docker compose up -d
```

Optional: create a `.env` in the repo root with:

- `EMBED_MODEL` (defaults to `BAAI/bge-reranker-v2-m3`)
- `HUGGING_FACE_HUB_TOKEN` (if required for model access)
- `VLLM_PORT` (defaults to `8002`)
- `VLLM_DTYPE` (defaults to `half`)
- `VLLM_MAX_MODEL_LEN` (defaults to `512`)
- `VLLM_MAX_NUM_SEQS` (defaults to `64`)
- `VLLM_GPU_MEMORY_UTILIZATION` (defaults to `0.01`)

Weights are cached in the Compose volume `hf-cache`.

## Try request

```bash
curl "http://127.0.0.1:8002/v1/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"BAAI/bge-reranker-v2-m3","input":"hello world"}'
```
