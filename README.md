### Installing the system:

* Simply run setup.sh on the desired machine running an Ubuntu-based Linux Distribution. Accept any necessary prompts.
* Django CMS will prompt the user to create an admin account with password during installation instead of relying on defaults.


### Editing the site:
* Navigate to the site URL and append /admin to reach the admin login. Use the account created during the installing stage to access administration priviledges. 
* The navigation bar across the top of the page makes it easy to reach the tools requiered to add and edit pages.
* Add text, image carousels, embedded videos, and so on, onto a page using the content sidebar while in edit mode.
  * The content sidebar can be called by selecting the icon in the far right of the toolbar

### Creating an Image Slider
* To create an image carousel, simply follow these instructions:
  * 1 - Log in to the administrator account
  * 2 - Select the content sidebar from the toolbar
  * 3 - Click the add button next to _Content_ and select _Carosuel_ under Bootstrap 4
  * 4 - Change any desired options and click _Save_
  * 5 - Select _NewsBlog_ from the _Application_ options dropdown menu
  * 6 - Click the add button next to _Carosuel_ and select _Carousel slide_ under Bootstrap 4
  * 7 - Select or upload an image using the pop up window, modify any desired options, and click _Save_

### Initializing The Blog
* To initialize the blog page, simply follow these instructions:
  * 1 - Log in to the administrator account
  * 2 - Select _Create_ from the toolbar
  * 3 - Select _New Page_ from the pop up menu
  * 4 - Once the page has been created, select _Advanced Settings_ from the _Page_ dropdown menu
  * 5 - Select _NewsBlog_ from the _Application_ options dropdown menu and click _Save_

### Creating Blog Posts:
* Our implementation for a blog is meant to allow editing of a post without publishing them:
  * The user can schedule a publish time and date for the draft posts 
  * Unpublished posts will have a unpublished banner underlayed beneath the post name on the blog overview page, that is normal. 
  * The published site will not show unpublished posts are not visible to the public, only administrators
* If the user wishes to create a blog post they follow these steps:
  * 1 - Log in as admin
  * 2 - Navigate to blog page
  * 3 - Select "Create" from toolbar
  * 4 - Select "New news/blog article" form options pop-up menu
  * 5 - Populate content accordingly
  * 6 - The user will automatically be directed to the unpublished "draft" of the post
    * 6.1 - Double click on the blog title to bring up publishing options
      * 6.1a - The publishing options also feature areas adding pictures and other files into the post, as well as scheduling future releases
      * 6.1b - If a future dated release is desired, simply chose a future date or time rather than the autopopulated current times
  * 7 - Select "Is published" option
  * 8 - Click "Save"

### Adding Links to the Navigation Bar
* To add a link to an external website, or to an additional program such as Mooshak, follow these steps:
  * Log in as admin
  * 1 - Log in to the administrator account
  * 2 - Select _Page_ from the toolbar
  * 3 - Select _Create Page_ and then _New Page_ from the dropdown menu
  * 4 - Fill in all desired information, and select _Save And Continue Editing_
  * 5 - Select advanced settings on the footer of the popup window
  * 6 - In the _Redirect_ field, enter the URL for the page to Redirect to
    * 6.1 - For Mooshak, the redirect would be "gusty.bike/mooshak"
  * 7 - Select _Save_ and hit _Publish Page Now_ in the toolbar
