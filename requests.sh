curl  \
    --request POST \
    --url "https://octodevelopment.atlassian.net/rest/api/3/search" \
    --user "k.vankorlaar@octo.nu:$JIRA_API_TOKEN" \
    --header "Content-Type: application/json"  
    --header "Accept: application/json" \
    --data-raw '{ "jql": "project = SEE and Sprint in openSprints()"}' | jsonnvim
