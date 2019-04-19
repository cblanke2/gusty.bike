#!/bin/bash
set -euo pipefail # Enable 'strict' mode

# Various directory variables
WEBSITE_NAME="gusty_bike"
INSTALLATION_DIR="/opt/$WEBSITE_NAME/"
VIRTENV_DIR="$INSTALLATION_DIR/virtenv/"
DJANGO_CMS_DIR="$INSTALLATION_DIR/django_cms/"

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
activate_venv
	python3 python3 "$DJANGO_CMS_DIR/manage.py" runserver
deactivate_venv
