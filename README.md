# Audit

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/audit`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'audit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install audit

## Usage

use "enable_audit" on model to enable tracking audits for that class.
you can specify which updates to track from "create", "update" or "destroy".
If you want to track associated relation as well you can use "associated_with" option for that purpose.
associated_with will be an array of association name that has to be tracked

reference_ids_without_associations:
This is type of field which will track association which are not actually specified on model but foreign id is stored on model. format to specify this option is as follows
{name_of_key: "actual name of key", method: "method by which this object can be accessed", klass: model name for the key}


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/audit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Audit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/audit/blob/master/CODE_OF_CONDUCT.md).
