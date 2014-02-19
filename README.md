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

Now, it validates your request and ensures the api! If response changes:

## Now it lets people use your schema to try your `live` api (e.g. on your staging server)

Add to `config/routes.rb`

    mount Fdoc::Server, at: '/fdoc'

Run after deploy

    bundle exec fdoc convert fdoc --output=public/fdoc -u "/fdoc"

Navigate to `http://your.staging.com/fdoс`

The interface there shows json-schema converted in a friendly way and
lets you try api endpoints `live`

[json_schema]: http://json-schema.org/
