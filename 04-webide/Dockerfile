FROM codercom/code-server:latest

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  sudo mv kubectl /usr/local/bin && sudo chmod +x /usr/local/bin/kubectl

CMD ["dumb-init", "/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080"]
