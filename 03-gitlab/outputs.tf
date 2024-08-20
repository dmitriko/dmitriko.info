output "gitlab_pwd" {
  sensitive = true
  value = data.kubernetes_secret.gitlab_pwd.data.password
}
