FROM codercom/code-server:latest

RUN  sudo apt update && sudo apt install -y python3-pip wget unzip && sudo pip3 install awscli --break-system-packages

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  sudo mv kubectl /usr/local/bin && sudo chmod +x /usr/local/bin/kubectl

CMD ["dumb-init", "/usr/bin/code-server", "--bind-addr", "0.0.0.0:8080"]
