# vLLM embeddings (Docker)

OpenAI-compatible embeddings on port **8002** (`/v1/embeddings`), using [vLLM](https://github.com/vllm-project/vllm) with `BAAI/bge-reranker-v2-m3` by default.

## Publish image (GitHub Actions)

On push to `main` or manual **workflow_dispatch**, [.github/workflows/docker-push.yml](.github/workflows/docker-push.yml) builds the [Dockerfile](Dockerfile) and pushes:

- `<dockerhub_user>/docker-vllm-embedding-v1:latest`
- `<dockerhub_user>/docker-vllm-embedding-v1:<git_sha>`

Repository secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.

## Local or GPU host (Compose)

Requires [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

```bash
docker compose up -d
```

Optional: create a `.env` in the repo root with `EMBED_MODEL` and/or `HUGGING_FACE_HUB_TOKEN` if you need them (see [docker-compose.yml](docker-compose.yml)). Weights are cached in the Compose volume `hf-cache`.

## Try embeddings

```bash
curl "http://127.0.0.1:8002/v1/embeddings" \
  -H "Content-Type: application/json" \
  -d '{"model":"BAAI/bge-reranker-v2-m3","input":"hello world"}'
```
# docker-vllm-reranker
