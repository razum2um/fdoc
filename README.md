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

By default all fields are marked as non-required (in request, as well as in response),
lets add "social_network" in request parameters and fill in "last_sign_in_at" in response:

Now, it validates your request and ensures the api! If response changes:

    1) Api::V1::UsersController registers user
     Failure/Error: post :create, {
     Fdoc::ValidationError:
       Request
       - The property '#/' contains additional properties ["social_network"] outside of the schema when none are allowed in schema c0ec70af-3d75-5a46-8206-a73a2b6250b3#
       Response
       - The property '#/user/last_sign_in_at' of type String did not match the following type: null in schema 83b0e4ef-4f9e-567e-ab37-8941366c0126#
       Diff
              required: []
       +    social_network:
       +      type: object
       +      properties:
       +        provider:
       +          type: string
       +        uid:
       +          type: string
       +      required: []
          required: []
                last_sign_in_at:
       -          type: 'null'
       -      required:
       -      - email
       +          type: string
       +      required: []
          required: []
     # ./spec/controllers/api/v1/users_controller_spec.rb:8:in `block (3 levels) in <top (required)>'
     # ./spec/controllers/api/v1/users_controller_spec.rb:7:in `block (2 levels) in <top (required)>'

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
