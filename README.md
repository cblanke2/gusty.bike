### Installing the system:

* Simply run setup.sh on the desired machine running an Ubuntu-based Linux Distribution. Accept any necessary prompts.

* Django CMS will prompt the user to create an admin account with password during installation instead of relying on defaults.


### Editing the site:

* Navigate to the site URL and append /admin to reach the admin login. Use the account created during the installing stage to access administration priviledges. 

* The navigation bar across the top of the page makes it easy to reach the tools requiered to add and edit pages.



### Creating Blog Posts:

* Our implementation for a blog is meant to allow editing of a post without publishing them:
  * The user can schedule a publish time and date for the draft posts 
  * Unpublished posts will have a unpublished banner underlayed beneath the post name on the blog overview page, that is normal. 
  * The published site will not show unpublished posts are not visible to the public, only administrators

* If the user wishes to create a blog post they follow these steps:
	* 1 Log in as admin
  * 2 Navigate to blog page
  * 3 Select "Create" from toolbar
  * 4 Select "New news/blog article" form options pop-up menu
  * 5 Populate content accordingly
  * 6 The user will automatically be directed to the unpublished "draft" of the post
    * 6.1 Double click on the blog title to brig up publishing options
      * 6.1a The publishing options also feature areas adding pictures and other files into the post, as well as scheduling future releases
      * 6.1b If a future dated release is desired, simply chose a future date or time rather than the autopopulated current times
  * 7 Select "Is published" option
  * 8 Click "Save"
