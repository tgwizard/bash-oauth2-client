set -e

client_id=valtech.test.bash.local
scope=profile%20email
authorize_url=$(echo "https://stage-id.valtech.com/oauth2/authorize?response_type=code&client_id=$client_id&scope=$scope")
token_url=https://stage-id.valtech.com/oauth2/token
user_info_url=https://stage-id.valtech.com/api/users/me

method=
path=
session_cookie=
authorization_code=

function parse_http_request {
  # First read method and path
  read method path version
  # echo $method
  # echo $path
  while read var
  do
    var=$(echo $var | tr -d '\r\n')

    # Extract session cookie
    session_cookie_re="Cookie:.*bashsessionid=([^;]+);?.*"
    if [[ "$var" =~ $session_cookie_re ]]; then
      session_cookie=${BASH_REMATCH[1]}
    fi

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
  </p>"

  if [[ -f ./sessions/$session_cookie.at ]]; then
    access_token=$(cat ./sessions/$session_cookie.at)
    user_info=$(curl -s -X GET -H "Authorization: Bearer $access_token" $user_info_url)
    user_name_re=".*\"name\": \"([^\"]+)\".*"
    if [[ "$user_info" =~ $user_name_re ]]; then
      user_name=${BASH_REMATCH[1]}
      echo "<p>You are signed in as $user_name.</p>"
    fi
  else
    echo "<p>You are NOT signed in.</p>"
  fi

  echo "</body></html>"
}

function render_sign_in {
  echo "HTTP/1.1 302 Found
Location: $authorize_url"
}

function render_sign_in_callback {
  at_response=$(curl -s -X POST -d "grant_type=authorization_code&client_id=$client_id&client_secret=$CLIENT_SECRET&code=$authorization_code" $token_url)

  at_re=".*\"access_token\": \"([^\"]+)\".*"
  if [[ "$at_response" =~ $at_re ]]; then
    access_token=${BASH_REMATCH[1]}
    session_id=$(uuidgen)
    echo $access_token > ./sessions/$session_id.at
    # We are redirecting using meta because the browser tries to
    # load regular redirect targets too quickly for our netcat server.
    echo "HTTP/1.1 200 OK
Set-Cookie: bashsessionid=$session_id; Path=/; HttpOnly
Content-Type: text/html

<html><head><meta http-equiv=\"refresh\" content=\"1;URL=/\"></head></html>
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

if [ "$path" == "/" ]; then
  render_start_page
elif [ "$path" == "/sign-in" ]; then
  render_sign_in
elif [[ "$path" =~ ^/sign-in/callback\?code=(.+)$ ]]; then
  authorization_code=${BASH_REMATCH[1]}
  render_sign_in_callback
else
  render_404
fi

exit 0
