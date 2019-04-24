$THIS_FILE_IS_INTERPRETED_USING_BASH
$ESCAPE_DOLLARS_WHERE_APPROPRIATE
import os
from os.path import (
    join as join_path,
    dirname
)


# NOTE - This will "include" the original settings file in this one.
exec(open(dirname(__file__) +  '/base_settings.py').read())


# SECURITY WARNING: don't run with debug turned on in production!
# Otherwise arbitrary users will be able to view settings, etc when
# encountering 404 errors, etc.
DEBUG = False

PROJECT_DIR = join_path(BASE_DIR, 'website')


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
    'website'
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
# NOTE - This assumes that a single template engine is configured.
TEMPLATES[0]['DIRS'] = [
    *TEMPLATES[0].get('DIRS', []),

    join_path(PROJECT_DIR, 'templates'),
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
        'NAME': os.path.join(BASE_DIR, "$DATABASE_FILE"),
    }
}


# ## Static Files Settings ## #
DATA_DIR = dirname(dirname(__file__))
STATIC_URL  = '/static/'
MEDIA_URL   = '/media/'
MEDIA_ROOT  = os.path.join(DATA_DIR, 'media')
STATIC_ROOT = os.path.join(DATA_DIR, 'static')

STATICFILES_DIRS = (
    os.path.join(PROJECT_DIR, 'static'),
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

CMS_TEMPLATES = [
    ## Customize this when using other templates.
    ("content.html", "content")
]


# Before uncommenting this, be sure to read the documentation at
# http://docs.django-cms.org/en/latest/reference/configuration.html#cms-languages
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