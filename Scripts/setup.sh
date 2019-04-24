#!/bin/bash
set -euo pipefail # Enable 'strict' mode


# ## CONFIGURATION VARIABLES ## #

# The domain name of the website.
# This is used in certain configuration files, and paths to determine directory
# names.
WEBSITE_NAME="gusty.bike"
WEBSITE_PATH_NAME="$(echo "$WEBSITE_NAME" | sed "s|\.|-|g")"

# The directory that the Django site, virtual environment, and static resources
# will be installed into.
# The path will be created if it doesn't already exist, and the owner will be
# set to 'www-data'.
INSTALLATION_DIR="/opt/$WEBSITE_PATH_NAME"

# The file path for the database. May be an abso
# If this is a relative path, the database will be created/looked for relative
# to the installation directory.
DATABASE_FILE="db.sqlite"

# The URL to download Mooshak from.
MOOSHAK_DOWNLOAD_URL='http://mooshak2.dcc.fc.up.pt/install/MooshakInstaller.jar'

# The URL to download the Bootstrap 4 templates for Aldryn NewsBlog from.
# The target of the URL is expected to be a zip file containing directories
# named "templates" and "static".
# Other directories may exist, however they will not be copied over
# to the website's project directory.
BLOG_BOILERPLATE_URL='https://github.com/johnfraney/aldryn-newsblog/archive/bootstrap4-boilerplate.zip'

# The URL to download the Bootstrap 4 templates for the CMS from.
# The target of the URL is expected to be a zip file containing directories
# named "templates" and "static".
# Other directories and files may exist, however they will not be copied over
# to the website's project directory.
CMS_BOILERPLATE_URL='https://github.com/divio/djangocms-boilerplate-bootstrap4/archive/master.zip'

# The CMS theme file. This is expected to be a CSS file that can be used in
# place of the default bootstrap.min.css file.
CMS_THEME_URL='https://bootswatch.com/4/united/bootstrap.min.css'

# ## END CONFIGURATION VARIABLES ## #


# Utility functions
function section(){
    echo ; echo
    echo "$1"
}

function find_replace(){
    FIND="$1" REPLACE="$2" \
        perl -pi -e 's/\Q$ENV{FIND}\E/$ENV{REPLACE}/g' "$3"
}

function apply_shell_expansion(){
    THIS_FILE_IS_INTERPRETED_USING_BASH=''
    ESCAPE_DOLLARS_WHERE_APPROPRIATE=''

    file="$1"
    data=$(< "$file")
    delimiter="__apply_shell_expansion_delimiter__"
    command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}


# Directory variables
SCRIPT_DIR="$(
    cd "$( dirname "${BASH_SOURCE[0]}" )"
    >/dev/null 2>&1 && pwd
)"

NGINX_SITE_FILE="$SCRIPT_DIR/nginx-site.conf"
DAEMON_UNIT_FILE="$SCRIPT_DIR/systemd.service"
DAEMON_SOCKET_FILE="$SCRIPT_DIR/systemd.socket"
GUNICORN_SETTINGS_FILE="$SCRIPT_DIR/gunicorn-settings.py"
DJANGO_SETTINGS_FILE="$SCRIPT_DIR/django-settings.py"
DJANGO_URLS_FILE="$SCRIPT_DIR/django-urls.py"

RUNFILES_DIR="/run/$WEBSITE_PATH_NAME/"
PID_FILE="$RUNFILES_DIR/pid"
SOCKET_FILE="$RUNFILES_DIR/socket"

VIRTENV_DIR="$INSTALLATION_DIR/virtenv"
DJANGO_CMS_DIR="$INSTALLATION_DIR/django_cms"
WEBSITE_DIR="$DJANGO_CMS_DIR/website"

DOWNLOAD_DIR="$(mktemp -d)"
CMS_BOILERPLATE_DIR="$(mktemp -d)"
BLOG_BOILERPLATE_DIR="$(mktemp -d)"


# ## File Data ## #
NGINX_SITE_DATA="$(apply_shell_expansion "$NGINX_SITE_FILE")"
DJANGO_SETTINGS_DATA="$(apply_shell_expansion "$DJANGO_SETTINGS_FILE")"
DJANGO_URLS_DATA="$(apply_shell_expansion "$DJANGO_URLS_FILE")"


# ## Prepare Setup Environment ## #
cd "$SCRIPT_DIR"


# ## Install required packages ## #
section "Installing system packages..."

    apt-get -y autoremove
    apt-get -y update
    apt-get -y upgrade
    apt-get -y install             \
        --upgrade                  \
        'nginx'                    \
        'python3-venv'             \
        'python3-pip'              \
        'openjdk-8-jdk'            \
        'openjdk-8-jre'            \


# ## Setup nginx ## #
section "Setting up nginx..."

    systemctl enable nginx
    mv '/etc/nginx/sites-available/default' \
       '/etc/nginx/sites-available/default.old' || true
    echo "$NGINX_SITE_DATA" > "/etc/nginx/sites-available/default"


# ## Setup website directories## #
    mkdir -p "$INSTALLATION_DIR"


# ## Install Mooshak ## #
section "Installing mooshak..."

    wget --no-check-certificate "$MOOSHAK_DOWNLOAD_URL"
    java -jar "MooshakInstaller.jar" -cui
    ln -fs "/home/mooshak" "$INSTALLATION_DIR/mooshak"


# ## Setup virtual environment ## #
section "Creating Python virtual environment..."

    # Create the virtual environment
    python3 -m venv "$VIRTENV_DIR"
    ln -fs "$VIRTENV_DIR/bin/python3" "$VIRTENV_DIR/bin/python"


    # Define helper functions for using the virtual environment
    function activate_venv(){
        set +euo pipefail
        source "$VIRTENV_DIR/bin/activate"
        set -euo pipefail
    }

    function deactivate_venv(){
        set +euo pipefail
        deactivate
        set -euo pipefail
    }


# ## Initialize the project ## #
section "Initializing djangoCMS website..."

    if [ ! -d "$WEBSITE_DIR" ]; then
        activate_venv
            # Install requirements
                pip3 install --upgrade pip
                pip3 install --upgrade wheel
                pip3 install --upgrade \
                    gunicorn                \
                    django-cms              \
                                            \
                    djangocms-bootstrap4    \
                    djangocms-modules       \
                    djangocms-history       \
                    djangocms_column        \
                    djangocms_file          \
                    djangocms_googlemap     \
                    djangocms_icon          \
                    djangocms_link          \
                    djangocms_picture       \
                    djangocms_snippet       \
                    djangocms_style         \
                    djangocms_text_ckeditor \
                    djangocms_video         \
                                            \
                    aldryn-newsblog         \
                                            \
                    django-sekizai          \
                    django-bootstrap4


            # Initialize the Django project
                mkdir -p "$DJANGO_CMS_DIR"
                django-admin.py startproject "website" "$DJANGO_CMS_DIR"
                mkdir -p "$WEBSITE_DIR/templates"
                mkdir -p "$WEBSITE_DIR/static"


            # Create and download CMS boilerplate
                wget -O "$DOWNLOAD_DIR/tmp.zip" "$CMS_BOILERPLATE_URL"
                unzip -d "$DOWNLOAD_DIR" "$DOWNLOAD_DIR/tmp.zip"
                find "$DOWNLOAD_DIR" \
                    -maxdepth 2      \
                    -mindepth 2      \
                    -exec mv {} "$CMS_BOILERPLATE_DIR" \;

                mv "$CMS_BOILERPLATE_DIR/templates" "$WEBSITE_DIR"
                mv "$CMS_BOILERPLATE_DIR/static"    "$WEBSITE_DIR"


            # Create and download blog boilerplate
                wget -O "$DOWNLOAD_DIR/tmp.zip" "$BLOG_BOILERPLATE_URL"
                unzip -d "$DOWNLOAD_DIR" "$DOWNLOAD_DIR/tmp.zip"
                find "$DOWNLOAD_DIR" \
                    -maxdepth 2      \
                    -mindepth 2      \
                    -exec mv {} "$BLOG_BOILERPLATE_DIR" \;

                rsync -av \
                    "$BLOG_BOILERPLATE_DIR/aldryn_newsblog/boilerplates/bootstrap4/" \
                    "$WEBSITE_DIR"


            # Create and download theme
                wget --directory-prefix "$DOWNLOAD_DIR" "$CMS_THEME_URL"
                mv "$DOWNLOAD_DIR/bootstrap.min.css" \
                   "$WEBSITE_DIR/static/css/bootstrap.min.css"


            # Modify navbar color scheme
                find_replace \
                    'navbar navbar-expand-lg navbar-light bg-light'  \
                    'navbar navbar-expand-lg navbar-dark bg-primary' \
                    "$WEBSITE_DIR/templates/base.html"


            # Modify navbar contents
                find_replace \
                    '<a class="navbar-brand" href="#">Brand</a>'          \
                    '<!-- <a class="navbar-brand" href="#">Brand</a> -->' \
                    "$WEBSITE_DIR/templates/base.html"


            # Modify default page title
                find_replace \
                    ' - {{ request.site.name }}' \
                    ''                           \
                    "$WEBSITE_DIR/templates/base.html"


            # Modify blog article layout
                find_replace \
                    '{% extends "aldryn_newsblog/fullwidth.html" %}'  \
                    '{% extends "aldryn_newsblog/two_column.html" %}' \
                    "$WEBSITE_DIR/templates/aldryn_newsblog/article_detail.html"

                find_replace \
                    '<nav class="aldryn-newsblog-pager">'      \
                    '<nav class="mt-5 aldryn-newsblog-pager">' \
                    "$WEBSITE_DIR/templates/aldryn_newsblog/article_detail.html"


            # Modify the settings and url files.
            mv "$WEBSITE_DIR/settings.py" "$WEBSITE_DIR/base_settings.py"
            echo "$DJANGO_SETTINGS_DATA" > "$WEBSITE_DIR/settings.py"

            mv "$WEBSITE_DIR/urls.py" "$WEBSITE_DIR/base_urls.py"
            echo "$DJANGO_URLS_DATA" > "$WEBSITE_DIR/urls.py"


            # Install templates

            # CMS_TEMPLATES = [
            #     ('home.html', 'Home page template'),
            # ]
        deactivate_venv
    fi


# ## Install service files ## #
cp $SCRIPT_DIR/start.sh $INSTALLATION_DIR
chmod +x $INSTALLATION_DIR/start.sh


# systemd files
apply_shell_expansion "$DAEMON_UNIT_FILE" \
    > "/etc/systemd/system/$WEBSITE_PATH_NAME.service"
chmod 660 "/etc/systemd/system/$WEBSITE_PATH_NAME.service"

apply_shell_expansion "$DAEMON_SOCKET_FILE" \
    > "/etc/systemd/system/$WEBSITE_PATH_NAME.socket"
chmod 660 "/etc/systemd/system/$WEBSITE_PATH_NAME.socket"


# gunicorn files
apply_shell_expansion "$GUNICORN_SETTINGS_FILE" \
    > "$WEBSITE_DIR/gunicorn-settings.py"
chmod 660 "$WEBSITE_DIR/gunicorn-settings.py"


systemctl daemon-reload
systemctl enable "$WEBSITE_PATH_NAME.service"
systemctl restart "$WEBSITE_PATH_NAME.service"


# Finalize project
activate_venv
    python3 "$DJANGO_CMS_DIR/manage.py" makemigrations
    python3 "$DJANGO_CMS_DIR/manage.py" collectstatic
    python3 "$DJANGO_CMS_DIR/manage.py" migrate
    python3 "$DJANGO_CMS_DIR/manage.py" createsuperuser --username admin
    chown -R www-data:www-data "$INSTALLATION_DIR"
    chmod -R o-rwx /opt/gusty-bike/
deactivate_venv


echo DONE
echo "Run 'sudo systemctl restart $WEBSITE_PATH_NAME.service nginx.service' to start the webserver."
