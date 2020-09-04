#!/bin/bash
# Cronjob task to get gitlan usage statistics
#
# Set env:
#  export GITLAB_HOST=""
#  export GITLAB_TOKEN=""
#  export PUSHGATEWAY_HOST="pushgateway.onecmd.com"
#
#  NOTE: GITLAB_TOKEN must be Gitlab administrator user token.
#
### Add to crontab
##  crontab -e
# */2 * * * * /opt/onecmd/gitlab_usage_exporter.sh >> /var/log/gitlab_statictis.log 2>&1
#

cur_time=`date`
cur_path=`pwd`
statistics_file=/tmp/gitlab_statistics.txt

gitlab_api_url="https://${GITLAB_HOST}/api/v4"
gitlab_token="${GITLAB_TOKEN}"
pushgateway_url="http://${PUSHGATEWAY_HOST}/metrics/job/gitlab_statistics"

echo "${cur_time}: Task starting..."

gitlab_resources=("groups" "projects" "users" "issues" "broadcast_messages" "events" "merge_requests" "merge_requests_opened" "merge_requests_merged" "namespaces" "runners" "snippets" "hooks" "todos")

function generate_statistics(){
	echo "# gitlab statistics" > ${statistics_file}

	for resource in ${gitlab_resources[@]}
	do
		resource_url=${resource}
		parameters="scope=all&per_page=1"
		if [ "X${resource}" == "Xrunners" ]; then
			parameters="per_page=1"
		elif [ "X${resource}" == "Xmerge_requests_opened" ]; then
			resource_url="merge_requests"
			parameters="scope=all&per_page=1&state=opened"
		elif [ "X${resource}" == "Xmerge_requests_merged" ]; then
			resource_url="merge_requests"
			parameters="scope=all&per_page=1&state=merged"
		fi

		total=`curl -sIL --proxy "" --header "Private-Token: ${gitlab_token}" ${gitlab_api_url}/${resource_url}?${parameters} | grep -Fi X-Total: | awk -F ':' '{print $2}' | dos2unix`

		if [ ! "X${total}" == "X" ]; then
			# echo "gitlab_statistics{label=\"${resource}\"} ${total}"
			echo "# Total ${resource}" >> ${statistics_file}
			echo "gitlab_statistics{label=\"${resource}\"} ${total}" >> ${statistics_file}
		fi
	done

	response=`curl -sL --proxy "" --header "Private-Token: ${gitlab_token}" ${gitlab_api_url}/issues_statistics?scope=all`
	if [ $? == 0 ]; then
		issue_closed=`echo $response | awk -F ':' '{print $5}' | awk -F ',' '{print $1}'`
		if [ ! "X${issue_closed}" == "X" ]; then
			echo "# Total issue_closed" >> ${statistics_file}
			echo "gitlab_statistics{label=\"issue_closed\"} ${issue_closed}" >> ${statistics_file}
		fi

		issue_opened=`echo $response | awk -F ':' '{print $6}' | awk -F '}' '{print $1}'`
		if [ ! "X${issue_opened}" == "X" ]; then
			echo "# Total issue_opened" >> ${statistics_file}
			echo "gitlab_statistics{label=\"issue_opened\"} ${issue_opened}" >> ${statistics_file}
		fi
	fi

	cat ${statistics_file} | curl -sL --proxy "" --data-binary @- ${pushgateway_url}
}

generate_statistics

echo "${cur_time}: Gitlab statistics: "
cat ${statistics_file}
