%{ for admin in admins ~}
- userarn: "arn:aws:iam::${account_id}:user/${admin}"
  username: ${admin}
  groups:
    - system:masters
%{ endfor ~}
%{ for user in users ~}
- userarn: "arn:aws:iam::${account_id}:user/${user}"
  username: ${user}
  groups: []
%{ endfor ~}