FROM vllm/vllm-openai:cu130-nightly
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--model","BAAI/bge-reranker-v2-m3","--task","score","--host","0.0.0.0","--port","8002","--dtype","half","--max-model-len","512","--max-num-seqs","64","--gpu-memory-utilization","0.15"]
