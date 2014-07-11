#!/bin/bash
#
# bash script that associates a micro service instance with the
# current working directory.  Captures the instance's FQDN and creates
# an authenticator that can be used to make authenticated HTTPS
# requests to that instance.
#
# These associations can be used by build systems to update, restart,
# reset, etc. the instance.
#
# Script asks for a micro service instance FQDN, owner name, and
# password. It uses those values to create a permanent authenticator
# and then stores the authenticator, FQDN, and username in the current
# working directory.
#
# The authenticator is stored in a curl compatible 'cookie jar' file
# named '.cookies'
#
# The FQDN is stored in the file '.hostname', the username in
# '.username'. While .hostname and .cookies files will typically be
# used by other programs to make connections, .username is only used
# by .associate.sh to provide a default value for the username on
# future runs.
#
# Once the association is established executing a curl command like:
#
#   curl --cookie .cookies https://$(cat .hostname)
#
# will fetch the '/' resource from the instance associated with the
# current working directory, without needing to type in a password, 
# hostname, or username.
# 
# The created authenticator can be destroyed by running:
#
#   curl --cookie .cookies -X POST https://$(cat .hostname)/usrvplatform/authentication/dologout
#
# in the current working directory.
#
# If the script thinks the user provided a bad username / password
# pair or a bad hostname it gives the user the opportunity to replace
# the potentially bad value(s) and tries to create the authenticator
# again.
#

set -e
#extra_curl_args="-s -S -D - "

# Make sure .cookies is readable only by the user
#
touch .cookies
chmod 600 .cookies

# Reading the FQDN from the user. First see if there is an old value
# we can use a default.
#
host_prompt="Enter fully qualified hostname (FQDN) of debugging / testing instance"

# Default fqdn
if [ -s .hostname ]; then
    default_fqdn=$(cat .hostname)
    host_prompt=${host_prompt}" [${default_fqdn}]"
fi
host_prompt=${host_prompt}": "

# Read the fqdn, providing the old value (if any) as a default
read -e -p "${host_prompt}" fqdn
if [ -z "${fqdn}" ]; then
    fqdn=${default_fqdn}
fi

# Read user name and password
#

# Default username
username_prompt="Enter owner username"
if [ -s .username ]; then
    default_username=$(cat .username)
    username_prompt=${username_prompt}" [${default_username}]"
fi
username_prompt=${username_prompt}": "
read -er -p "${username_prompt}" username
if [ -z "$username" ]; then
    username=${default_username}
fi

read -er -s -p "Enter password: " password
echo

# Try to create the authenticator, catching common error and retrying.
#
while [ true ]; do
    # curl command to create an authenticator
    curl_command="curl -k --fail --cookie-jar .cookies $extra_curl_args -X POST -d username=${username} -d password=${password} https://${fqdn}/usrvplatform/authentication/dodurablelogin"

    curl_rslt=0
    ${curl_command} || curl_rslt=$?

    # Sucess or error?
    case ${curl_rslt} in
        0)
            break # success
            ;;
        6)
            # Give the user the option of providing a new hostname
            #
            echo "Bad host" 
            host_prompt=${host_prompt}": "
            if [ -n "${default_fqdn}" ]; then
                host_prompt=${host_prompt}" [${default_fqdn}]"
            fi
            host_prompt=${host_prompt}": "

            # Read the fqdn, providing the old value (if any) as a default
            read -e -p "${host_prompt}" fqdn
            if [ -z "${fqdn}" ]; then
                fqdn=${default_fqdn}
            fi
            ;;
        22)
            # Give the user the option to provide a new name / password
            #
            echo "Bad username / password" 

            # Since the password is likey wrong, give user an option
            # to see it.
            #
            read -er -p "Show password?[y/N]: " show_password
            password_show="-s"
            if [ "${show_password}" == "y" ]; then
                password_prompt="Enter password [$password]: "
                password_show=""
            else
                password_prompt="Enter password: "
            fi

            # Do the actual asking for of user name and password
            old_username=${username}
            read -er -p "Enter owner username: [${old_username}]: " username
            if [ -z "$username" ]; then
                username=${old_username}
            fi

            old_password=${password}
            read -er ${password_show} -p "${password_prompt}" password

            if [ "${show_password}" != "y" ]; then
                echo
            fi

            if [ -z "${password}" ]; then
                password=${old_password}
            fi

            ;;
        *)
            # Don't know what happend, given them the curl command to try out
            # (after x-ing out the password).
            #
            echo "Unexpected curl error:" ${curl_rslt}
            echo "Try curl command from command line:" 
            echo ${curl_command/"password=$password"/"password=XXXXXXXX"}
            exit 1
            ;;
        esac
done

# If we created an authenticator (if we didn't we exit before getting
# here) the user provided data must be good so remember the hostname
# and username.
#
echo "Remembering instance hostname."
echo $fqdn > .hostname
echo "Remembering instance username."
echo $username > .username
