$THIS_FILE_IS_INTERPRETED_USING_BASH
$ESCAPE_DOLLARS_WHERE_APPROPRIATE
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
    # Sitemap URLs
    url(
        r'^sitemap\.xml\$',
        sitemap,
        {'sitemaps': {'cmspages': CMSSitemap}}
    ),

    # Locale-aware URLs
    *i18n_patterns(
        # Admin console URLs
        url(r'^admin/', admin.site.urls),

        # CMS URLs
        url(r'^', include('cms.urls')),
    ),

    # Filer URLs
    url(r'^filer/', include('filer.urls')),
]


# This is only needed when using runserver.
if settings.DEBUG:
    urlpatterns = [
        *urlpatterns,
        *staticfiles_urlpatterns(),
        url(
            r'^media/(?P<path>.*)\$',
            serve,
            {
                'document_root': settings.MEDIA_ROOT,
                'show_indexes': True
            }
        ),
    ]
