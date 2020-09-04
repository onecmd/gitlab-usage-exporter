# gitlab-usage-exporter
This is an Prometheus Push-gateway exporter tool for Gitlab usage data, such as Total users, projects, groups, merger request and so on. It will send these data to Push-gateway.

Exporter metrics for gitlab usage:
- broadcast_messages
- events
- groups
- hooks
- issue_closed
- issue_opened
- issues
- merge_requests
- merge_requests_merged
- merge_requests_opened
- namespaces
- projects
- runners
- snippets
- todos
- users

## Usage

### Set env
```
export GITLAB_HOST="gitlab.onecmd.com"
export GITLAB_TOKEN="Gitlab_administrator_token"
export PUSHGATEWAY_HOST="pushgateway.onecmd.com"
```

NOTE: GITLAB_TOKEN must be Gitlab administrator user [token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html).


### Add to crontab
```
#crontab -e
*/2 * * * * /opt/onecmd/gitlab_usage_exporter.sh >> /var/log/gitlab_statictis.log 2>&1
```
Also can add to Kubernetes cronjob if use Kubernetes.
