# JSON Api Tester: test your api and let people try it in an easy way

This gem is quite opinionated and relies on rails & rspec. If you're 
using anything else, please take a look at more liberal gems `api_taster` or `fdoc`,
preseeders of this gem.

## Usage

Add fdoc to your Gemfile.

    gem 'fdoc', github: 'razum2um/fdoc', require: 'fdoc/server'

Add fdoc to spec/spec_helper.rb

    require 'fdoc/spec_watcher'

Write your contorller specs as usual, but add `:fdoc` mark

    describe Api::V1::UsersController, :fdoc, type: :controller do
      render_views

      it 'registers user' do
        expect {
          post :create, user: {
            email: 'ad@ad.ad',
            password: '12345678',
            password_confirmation: '12345678'
          }
          expect(response).to be_success
        }.to change { User.count } .by 1
      end
    end

Run your specs normally and make them pass. Thats all, easy!

## Now it validates your api!

After successful spec passing there will be some files under Rails.root/fdoc directory

    fdoc
    ├── MyRailsApplication.fdoc.service
    ├── api
    │   └── v1
    │       └── users-POST.fdoc

please, commit them as they appear. They include description of request-response pair using
[JSON schema][json_schema] format (draft v4). Feel free to edit `required` and `description` fields!

By default all fields are marked as non-required (in request, as well as in response), lets change it

    diff --git c/fdoc/api/v1/users-POST.fdoc i/fdoc/api/v1/users-POST.fdoc
    -      required: []
    +      required: ['email']

Now, it validates your request and ensures the api! If response changes:

    All examples were filtered out; ignoring {:focus=>true}
      1) Api::V1::UsersController registers user
         Failure/Error: post :create, user: {
         JSON::Schema::ValidationError:
           The property '#/user' did not contain a required property of 'email' in schema d95e840e-f749-5fe2-82f2-9b567224b3c0#

## Now it lets people use your schema to try your `live` api (e.g. on your staging server)

Add to `config/routes.rb`

    mount Fdoc::Server, at: '/fdoc'

Add to the `Capfile`

    require 'fdoc/capistrano'

    # or run after deploy
    bundle exec fdoc convert fdoc --output=public/fdoc -u "/fdoc"

Navigate to `http://your.staging.com/fdoс`

# Request description

![request][request_img]

# Response description

![response][response_img]

# Live test

![tryrequest][tryrequest_img]

The interface there shows json-schema converted in a friendly way and
lets you try api endpoints `live`

[json_schema]: http://json-schema.org/
[request_img]: https://github.com/razum2um/fdoc/raw/master/docs/request.png
[response_img]: https://github.com/razum2um/fdoc/raw/master/docs/response.png
[tryrequest_img]: https://github.com/razum2um/fdoc/raw/master/docs/tryrequest.png
