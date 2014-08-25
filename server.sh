set -e

method=
path=
authorization_code=

function parse_http_request {
  # First read method and path
  read method path version
  # echo $method
  # echo $path
  while read var
  do
    var=$(echo $var | tr -d '\r\n')
    #echo "$var"
    if [ -z "$var" ]; then
      break
    fi
  done
}

function render_start_page {
  echo "HTTP/1.1 200 OK
Content-Type: text/html

<html>
<head><title>BASH OAuth Client</title></head>
<body>
  <h1>Hi from bash!</h1>
  <p>
  This is a server running on netcat and bash.
  You can perform an authorization code grant flow.
  <a href=\"/sign-in\">Try it now!</a>
  </p>
</body>
"
}

function render_sign_in {
  echo "HTTP/1.1 302 Found
Location: https://stage-id.valtech.com/oauth2/authorize?response_type=code&client_id=valtech.test.bash.local&scope=profile%20email"
}

function render_sign_in_callback {
  at_response=$(curl -s -X POST -d "grant_type=authorization_code&client_id=valtech.test.bash.local&client_secret=$CLIENT_SECRET&code=$authorization_code" https://stage-id.valtech.com/oauth2/token)

  at_re=".*\"access_token\": \"([^\"]+)\".*"
  if [[ "$at_response" =~ $at_re ]]
  then
    access_token=${BASH_REMATCH[1]}
    user_info=$(curl -s -X GET -H "Authorization: Bearer $access_token" https://stage-id.valtech.com/api/users/me)
    echo "HTTP/1.1 200 OK
Content-Type: application/json

$user_info
"
  else
    echo "HTTP/1.1 400 OK
Content-Type: application/json

$at_response
"
  fi

}

function render_404 {
  echo "HTTP/1.1 404 Not Found
Content-Type: text/html

<html>
<head><title>BASH OAuth Client</title></head>
<body>
  <h1>404 Not Found</h1>
  <p>Resource "$path" could not be found.</p>
</body>
"
}

parse_http_request

if [ "$path" == "/" ]
then
  render_start_page
elif [ "$path" == "/sign-in" ]
then
  render_sign_in
elif [[ "$path" =~ ^/sign-in/callback\?code=(.+)$ ]]
then
  authorization_code=${BASH_REMATCH[1]}
  render_sign_in_callback
else
  render_404
fi

exit 0
