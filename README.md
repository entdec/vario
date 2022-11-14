# Vario

Vario allows configuration over multiple levels and tied to different objects. It is a simple and flexible way to configure your project.

## Usage

Add the vario.rb initializer to your project and configure it.
Say your way to separate tenants is using an Account model, you would make 'Account' the settable and you can configure settings on it:

```ruby
Vario.setup do |config|
  config.key :environment, name: 'Environment', type: :select, collection_proc: -> { [%w[Production production], %w[Test test], %w[Development development]] }, value_proc: -> { Rails.env }

  config.for_settable_type 'Account' do |settable|
    settable.raise_on_undefined true

    settable.setting 'internationalization.default_currency', type: :string, default: 'USD', description: 'Default currency for new products.', collection_proc: -> { Money::Currency.map { |currency| ["#{currency.iso_code} - #{currency.name}", currency.iso_code] }.sort }
    settable.setting 'internationalization.week_start', type: :symbol, default: :monday, description: 'First day of the week', collection: [['Monday', :monday], ['Tuesday', :tuesday], ['Wednesday', :wednesday], ['Thursday', :thursday], ['Friday', :friday], ['Saturday', :saturday], ['Sunday', :sunday]]
  end
end
```

Next add vario to your routes.rb:

```ruby
  mount Vario::Engine, at: "/settings", as: "vario"
```

Then add a menu entry, or link to the settings page:

```ruby
link_to("Settings", vario.settings_path(settable: Current&.account&.to_sgid(for: "Vario").to_s))
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vario'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install vario
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
