FROM registry.access.redhat.com/ubi9/ubi-minimal

RUN microdnf install -y python3 python3-pip && \
    pip3 install --no-cache-dir "python-lsp-server[all]" && \
    microdnf clean all

WORKDIR /workspace

CMD ["pylsp", "--tcp", "--host", "0.0.0.0", "--port", "3333"]
