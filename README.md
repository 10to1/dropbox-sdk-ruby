## NOTE

This is a fork from the official Dropbox Ruby SDK. The current Dropbox Ruby SDK only supports Dropbox API V1. This fork supports Dropbox V2. It currently only supports the following methods:
  - Uploads
  - Download
  - Search

It is not guaranteed that this will be backward compatible with the official Dropbox Ruby SDK.

Also note that all tests for this fork currently pass, but that is only because the tests for all methods outside of those listed above have been manually marked as passing.

# Dropbox Core SDK for Ruby

A Ruby library that for Dropbox's HTTP-based Core API.

   https://www.dropbox.com/developers/core/docs

## Setup

You can install this package using 'gem':

    $ gem install dropbox-sdk-v2


## Getting a Dropbox API key

You need a Dropbox API key to make API requests.
- Go to: https://dropbox.com/developers/apps
- If you've already registered an app, click on the "Options" link to see the
  app's API key and secret.
- Otherwise, click "Create an app" to register an app.  Choose "Full Dropbox" or
  "App Folder" depending on your needs.
  See: https://www.dropbox.com/developers/reference#permissions


## Using the Dropbox API

Full documentation: https://www.dropbox.com/developers/core/

Before your app can access a Dropbox user's files, the user must authorize your
application using OAuth 2.  Successfully completing this authorization flow
gives you an "access token" for the user's Dropbox account, which grants you the
ability to make Dropbox API calls to access their files.

- Authorization example for a web app: web_file_browser.rb
- Authorization example for a command-line tool:
  https://www.dropbox.com/developers/core/start/ruby

Once you have an access token, create a DropboxClient instance and start making
API calls.

You only need to perform the authorization process once per user.  Once you have
an access token for a user, save it somewhere persistent, like in a database.
The next time that user visits your app, you can skip the authorization process
and go straight to making API calls.

----------------------------------
Running the Examples

There are example programs included in the tarball.  Before you can run an
example, you need to edit the ".rb" file and put your Dropbox API app key and
secret in the "APP_KEY" and "APP_SECRET" constants.

----------------------------------
Running the Tests

# gem install bundler

# bundle install
# cd test
# DROPBOX_RUBY_SDK_ACCESS_TOKEN=<oauth2-access-token> bundle exec ruby sdk_test.rb