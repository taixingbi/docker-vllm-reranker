FROM vllm/vllm-openai:latest
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--model","BAAI/bge-reranker-v2-m3","--runner","pooling","--convert","classify","--host","0.0.0.0","--port","8002","--dtype","half","--max-model-len","512","--gpu-memory-utilization","0.01"]
