set -e

client_id="430264288286-qgao3c1j7lal64i93gb598lil0l2mt7s.apps.googleusercontent.com"
client_secret="2DxdS9frBTHkFf4eibgnBJpi"
scope=profile
authorize_url=$(echo "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=$client_id&scope=$scope&redirect_uri=http%3A%2F%2Flocalhost%3A8998%2Fsign-in%2Fcallback")
token_url=https://accounts.google.com/o/oauth2/token
user_info_url=https://www.googleapis.com/plus/v1/people/me

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
<head><title>Bash OAuth2 Test Client</title></head>
<body>
  <h1>Hi from bash!</h1>
  <p>
  This is a server running on netcat and bash.
  It can perform an OAuth 2 authorization code grant flow.
  Try it now by
  <a href=\"/sign-in\">signing in via Google</a>.
  </p>"

  if [[ -f ./sessions/$session_cookie.at ]]; then
    access_token=$(cat ./sessions/$session_cookie.at)
    user_info=$(curl -s -X GET -H "Authorization: Bearer $access_token" $user_info_url)
    user_name_re=".*\"displayName\": \"([^\"]+)\".*"
    if [[ "$user_info" =~ $user_name_re ]]; then
      user_name=${BASH_REMATCH[1]}
      echo "<p>You are signed in as $user_name.</p>"
    else
      echo "<pre>$user_info</pre>"
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
  at_response=$(curl -s -X POST -d "grant_type=authorization_code&client_id=$client_id&client_secret=$client_secret&code=$authorization_code&redirect_uri=http%3A%2F%2Flocalhost%3A8998%2Fsign-in%2Fcallback" $token_url)

  at_re=".*\"access_token\" *: *\"([^\"]+)\".*"
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
<head><title>Bash OAuth2 Test Client</title></head>
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
