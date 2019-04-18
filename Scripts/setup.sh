#!/bin/bash
set -euo pipefail # Enable 'strict' mode


# ## CONFIGURATION VARIABLES ## #

# Used to determine the name of the Django project, as well as the name of the
# installation directory.
WEBSITE_NAME="gusty_bike"

# The domain name (without protocol or subdomain prefixes) of the website.
# Used to set some initial Django settings.
DOMAIN_NAME="gusty.bike"

# The directory that the Django site, virtual environment, and static resources
# will be installed into.
# The path will be created if it doesn't already exist, and the owner will be
# set to 'www-data'.
INSTALLATION_DIR="/opt/$WEBSITE_NAME/"

# The URL to download Mooshak from.
MOOSHAK_DOWNLOAD_URL='http://mooshak2.dcc.fc.up.pt/install/MooshakInstaller.jar'

# The URL to download the Bootstrap 4 templates for Aldryn NewsBlog from.
BLOG_BOILERPLATE_URL='https://github.com/johnfraney/aldryn-newsblog/archive/bootstrap4-boilerplate.zip'

# The URL to download the Bootstrap 4 templates for the CMS from.
CMS_BOILERPLATE_URL='https://github.com/divio/djangocms-boilerplate-bootstrap4/archive/master.zip'

# The CMS theme file.
CMS_THEME_URL='https://bootswatch.com/4/united/bootstrap.min.css'


# Utility functions
function section(){
	echo ; echo
	echo "$1"
}


# Directory variables
VIRTENV_DIR="$INSTALLATION_DIR/virtenv/"
DJANGO_CMS_DIR="$INSTALLATION_DIR/django_cms/"
WEBSITE_DIR="$DJANGO_CMS_DIR/$WEBSITE_NAME"

DOWNLOAD_DIR="`mktemp -d`"
CMS_BOILERPLATE_DIR="`mktemp -d`"
BLOG_BOILERPLATE_DIR="`mktemp -d`"
CMS_THEME_DIR="`mktemp -d`"

REPO_DIR="$(dirname "$0")"


# ## Prepare Setup Environment
cd "$REPO_DIR"


## Install required packages ## #
section "Installing system packages..."

	add-apt-repository -y 'ppa:webupd8team/java'

	apt-get -y autoremove
	apt-get -y update
	apt-get -y upgrade
	apt-get -y install             \
		--upgrade                  \
		'nginx'                    \
		'python3-venv'             \
		'python3-pip'              \
		'oracle-java8-installer'   \
		'oracle-java8-set-default'


## Setup nginx ## #
section "Setting up nginx..."

	systemctl enable nginx
	mv '/etc/nginx/sites-available/default' '/etc/nginx/sites-available/default.old' || true
	cat > "/etc/nginx/sites-available/default" <<- EOL
	server 
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name gusty.bike;

        location /static/ {
                root $DJANGO_CMS_DIR/static;
        }

        location / {
                proxy_pass http://localhost:8000/;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Host \$host;
                proxy_cache_bypass \$http_upgrade;
        }

        location /mooshak {
                proxy_pass http://localhost:8180/mooshak;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Host \$host;
                proxy_cache_bypass \$http_upgrade;
        }
	}
	EOL


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
				django-admin.py startproject "$WEBSITE_NAME" "$DJANGO_CMS_DIR"
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

				rsync -av "$BLOG_BOILERPLATE_DIR/aldryn_newsblog/boilerplates/bootstrap4/" "$WEBSITE_DIR"


			# Create and download theme
				wget --directory-prefix "$DOWNLOAD_DIR" "$CMS_THEME_URL"
				mv "$DOWNLOAD_DIR/bootstrap.min.css" "$WEBSITE_DIR/static/css/bootstrap.min.css"

			# Modify navbar color scheme
				FIND='navbar navbar-expand-lg navbar-light bg-light'
				REPLACE='navbar navbar-expand-lg navbar-dark bg-primary'
				sed -i -e "s|$FIND|$REPLACE|g" "$WEBSITE_DIR/templates/base.html"

			# Modify navbar contents
				FIND='<a class="navbar-brand" href="#">Brand</a>'
				REPLACE='<!-- <a class="navbar-brand" href="#">Brand</a> -->'
				sed -i -e "s|$FIND|$REPLACE|g" "$WEBSITE_DIR/templates/base.html"

			# Modify default page title
				FIND='<title>{% block title %}{% page_attribute page_title %} - {{ request.site.name }}{% endblock title %}</title>'
				REPLACE='<title>{% block title %}{% page_attribute page_title %}{% endblock title %}</title>'
				sed -i -e "s|$FIND|$REPLACE|g" "$WEBSITE_DIR/templates/base.html"

			# Modify blog article layout
				FIND='{% extends "aldryn_newsblog/fullwidth.html" %}'
				REPLACE='{% extends "aldryn_newsblog/two_column.html" %}'
				sed -i -e "s|$FIND|$REPLACE|g" "$WEBSITE_DIR/templates/aldryn_newsblog/article_detail.html"

				FIND='<nav class="aldryn-newsblog-pager">'
				REPLACE='<nav class="mt-5 aldryn-newsblog-pager">'
				sed -i -e "s|$FIND|$REPLACE|g" "$WEBSITE_DIR/templates/aldryn_newsblog/article_detail.html"

			# Modify the settings file.
			mv "$WEBSITE_DIR/settings.py" "$WEBSITE_DIR/base_settings.py"

			cat > "$WEBSITE_DIR/settings.py" <<- EOL
				import os
				from os.path import join as join_path

				exec(open(os.path.dirname(__file__) +  '/base_settings.py').read())

				# SECURITY WARNING: don't run with debug turned on in production!
				DEBUG = True


				ALLOWED_HOSTS.extend([
				    "$(wget -q -O /dev/stdout http://checkip.dyndns.org/ | cut -d : -f 2- | cut -d \< -f -1)".strip()
				])


				# Enabled Applications/Plugins
				# Note that order can matter!
				INSTALLED_APPS = [
				    'djangocms_admin_style',

				    *INSTALLED_APPS,

				    # Core CMS Applications
				    'cms',
				    'django.contrib.sites',
				    'menus',
				    'treebeard',

				    # Misc Requirements
				    'bootstrap4',
				    'easy_thumbnails',
				    'filer',
				    'parler',
				    'sekizai',
				    'sortedm2m',
				    'taggit',

				    # Secondary CMS Applications
				    'djangocms_column',
				    'djangocms_file',
				    'djangocms_googlemap',
				    'djangocms_icon',
				    'djangocms_link',
				    'djangocms_modules',
				    'djangocms_history',
				    'djangocms_picture',
				    'djangocms_snippet',
				    'djangocms_style',
				    'djangocms_text_ckeditor',
				    'djangocms_video',

				    # Bootstrap 4 Support
				    'djangocms_bootstrap4',
				    'djangocms_bootstrap4.contrib.bootstrap4_alerts',
				    'djangocms_bootstrap4.contrib.bootstrap4_badge',
				    'djangocms_bootstrap4.contrib.bootstrap4_card',
				    'djangocms_bootstrap4.contrib.bootstrap4_carousel',
				    'djangocms_bootstrap4.contrib.bootstrap4_collapse',
				    'djangocms_bootstrap4.contrib.bootstrap4_content',
				    'djangocms_bootstrap4.contrib.bootstrap4_grid',
				    'djangocms_bootstrap4.contrib.bootstrap4_jumbotron',
				    'djangocms_bootstrap4.contrib.bootstrap4_link',
				    'djangocms_bootstrap4.contrib.bootstrap4_listgroup',
				    'djangocms_bootstrap4.contrib.bootstrap4_media',
				    'djangocms_bootstrap4.contrib.bootstrap4_picture',
				    'djangocms_bootstrap4.contrib.bootstrap4_tabs',
				    'djangocms_bootstrap4.contrib.bootstrap4_utilities',

				    # Blog Support
				    'aldryn_apphooks_config',
				    'aldryn_categories',
				    'aldryn_common',
				    'aldryn_newsblog',
				    'aldryn_people',
				    'aldryn_translation_tools',

				    # Core Site
				    'gusty_bike'
				]


				# Enabled Middleware.
				# Note that order can matter!
				MIDDLEWARE = [
				    *MIDDLEWARE,

				    'django.middleware.locale.LocaleMiddleware',
				    'cms.middleware.user.CurrentUserMiddleware',
				    'cms.middleware.page.CurrentPageMiddleware',
				    'cms.middleware.toolbar.ToolbarMiddleware',
				    'cms.middleware.language.LanguageCookieMiddleware',
				    'cms.middleware.utils.ApphookReloadMiddleware',

				]


				# Template Engines Settings
				# Note - This assumes that a single template engine is configured.
				TEMPLATES[0]['DIRS'] = [
				    *TEMPLATES[0].get('DIRS', []),

				    join_path(BASE_DIR, 'gusty_bike', 'templates'),
				]

				TEMPLATES[0]['OPTIONS']['context_processors'] = [
				    *TEMPLATES[0]['OPTIONS'].get('context_processors', []),

				    'django.template.context_processors.i18n',
				    'django.template.context_processors.media',
				    'django.template.context_processors.csrf',
				    'django.template.context_processors.tz',
				    'django.template.context_processors.static',

				    'cms.context_processors.cms_settings',

				    'sekizai.context_processors.sekizai',
				]


				del TEMPLATES[0]['APP_DIRS']
				TEMPLATES[0]['OPTIONS']['loaders'] = [
				    *TEMPLATES[0]['OPTIONS'].get('loaders', []),

				    'django.template.loaders.filesystem.Loader',
				    'django.template.loaders.app_directories.Loader',
				]


				# ## Language / Time Settings ## #
				LANGUAGE_CODE = 'en'
				LANGUAGES = [
				    ('en', 'English'),
				]

				TIME_ZONE = 'US/Eastern'

				USE_I18N = True
				USE_L10N = True
				USE_TZ = True


				# ## Database Settings ## #
				DATABASES = {
				    'default': {
				        'ENGINE': 'django.db.backends.sqlite3',
				        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
				    }
				}


				# ## Static Files Settings ## #
				DATA_DIR = os.path.dirname(os.path.dirname(__file__))
				STATIC_URL  = '/static/'
				MEDIA_URL   = '/media/'
				MEDIA_ROOT  = os.path.join(DATA_DIR, 'media')
				STATIC_ROOT = os.path.join(DATA_DIR, 'static')

				STATICFILES_DIRS = (
				    os.path.join(BASE_DIR, 'gusty_bike', 'static'),
				)


				# ## easy_thumbnail Settings ## #
				THUMBNAIL_PROCESSORS = (
				    'easy_thumbnails.processors.colorspace',
				    'easy_thumbnails.processors.autocrop',
				    'filer.thumbnail_processors.scale_and_crop_with_subject_location',
				    'easy_thumbnails.processors.filters',
				    'easy_thumbnails.processors.background'
				)


				# ## News/Blog Settings ## #
				ALDRYN_NEWSBLOG_UPDATE_SEARCH_DATA_ON_SAVE = True


				# ## CMS settings ## #
				SITE_ID = 1

				CMS_PERMISSION = True

				CMS_PLACEHOLDER_CONF = {}

				CMS_TEMPLATES = [
				    ## Customize this
				    ("content.html", "content")
				]


				# Before uncommenting this, be sure to read the documentation at
				# http://docs.django-cms.org/en/latest/reference/configuration.html#cms-languages
				#
				gettext = lambda s: s
				CMS_LANGUAGES = {
				    1: [
				        {
				            'code': 'en',
				            'name': gettext('en'),
				            'redirect_on_fallback': True,
				            'public': True,
				            'hide_untranslated': False,
				        },
				    ],
				    'default': {
				        'redirect_on_fallback': True,
				        'public': True,
				        'hide_untranslated': False,
				    },
				}
			EOL


			# Modify the urls file.
			mv "$WEBSITE_DIR/urls.py" "$WEBSITE_DIR/base_urls.py"

			cat > "$WEBSITE_DIR/urls.py" <<- EOL
				import os
				from cms.sitemaps import CMSSitemap
				from django.conf import settings
				from django.conf.urls import include, url
				from django.conf.urls.i18n import i18n_patterns
				from django.contrib import admin
				from django.contrib.sitemaps.views import sitemap
				from django.contrib.staticfiles.urls import staticfiles_urlpatterns
				from django.views.static import serve

				exec(open(os.path.dirname(__file__) +  '/base_urls.py').read())

				admin.autodiscover()
				urlpatterns = [
				    url(r'^sitemap\.xml$', sitemap,
				        {'sitemaps': {'cmspages': CMSSitemap}}),
				]
				urlpatterns += i18n_patterns(
				    url(r'^admin/', admin.site.urls),
				    url(r'^', include('cms.urls')),
				)
				# This is only needed when using runserver.
				if settings.DEBUG:
				    urlpatterns = [
				        url(r'^media/(?P<path>.*)$', serve,
				            {'document_root': settings.MEDIA_ROOT, 'show_indexes': True}),
				        ] + staticfiles_urlpatterns() + urlpatterns
			EOL


			# Configure migrations
			mkdir -p "$WEBSITE_DIR/migrations"
			cat > "$WEBSITE_DIR/migrations/0001_update_site_name.py" <<- EOL
				from django.db import migrations
				from django.conf import settings


				def update_site_name(apps, schema_editor):
				    SiteModel = apps.get_model('sites', 'Site')
				    domain = '$DOMAIN_NAME'

				    SiteModel.objects.update_or_create(
				        pk=settings.SITE_ID,
				        domain=domain,
				        name=domain
				    )


				class Migration(migrations.Migration):

				    dependencies = [
				        # Make sure the dependency that was here by default is also included here
				        ('sites', '0002_alter_domain_unique'),
				    ]

				    operations = [
				        migrations.RunPython(update_site_name),
				    ]
			EOL


			# Install templates

			# CMS_TEMPLATES = [
			#     ('home.html', 'Home page template'),
			# ]
		deactivate_venv
	fi


# ## Install service files ## #


# Finalize project
activate_venv
	python3 "$DJANGO_CMS_DIR/manage.py" makemigrations
	python3 "$DJANGO_CMS_DIR/manage.py" collectstatic
	python3 "$DJANGO_CMS_DIR/manage.py" migrate
	python3 "$DJANGO_CMS_DIR/manage.py" createsuperuser --username admin
	chown -R www-data:www-data "$INSTALLATION_DIR"
deactivate_venv


echo DONE


