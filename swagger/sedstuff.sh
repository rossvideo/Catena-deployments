curl "https://smpte.github.io/st2138-a/docs/openapi.yaml" -o /usr/share/nginx/html/openapi.yaml

#check if the URLS env var is set
if [ -n "$ST2138_URLS" ]; then
  #use sed to replace the server section in the openapi.yaml file with the URLS
  #URLS will be in the format [{url:"",name:""},]
  #we need to convert it to the format required by swagger
  #which is
  #servers:
  #- url: ""
  #- url: ""
  #we can do this by using a loop to iterate over the URLS and create the servers section
  SERVERS="servers:"
  echo "Processing ST2138_URLS: $ST2138_URLS"
  for entry in $(echo $ST2138_URLS | jq -c '.[]'); do
    echo "Processing entry: $entry"
    URL=$(echo $entry | jq -r '.url')
    NAME=$(echo $entry | jq -r '.name')
    echo "Processing entry: URL=$URL, NAME=$NAME"
    SERVERS="$SERVERS\n- url: $URL \n  description: $NAME"
  done
  #now replace the servers section in the openapi.yaml file
  sed -i "s|servers:|$SERVERS|" /usr/share/nginx/html/openapi.yaml
  echo "sed 2"
  sed -i "\|  - url: https://device.catenamedia.tv:443/st2138-api/v1|d" /usr/share/nginx/html/openapi.yaml
fi
