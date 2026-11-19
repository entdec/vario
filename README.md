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

The settings pages show the topics of the current settable, which you set in the initializer:

```ruby
Vario.setup do |config|
  config.current_settable = -> { Current.account }
end
```

Then add a menu entry, or link to the settings page:

```ruby
link_to("Settings", vario.topics_path)
```

The settings pages need importmap-rails, Propshaft and Tailwind CSS 4 through tailwindcss-rails 4.3 or later (for engine support), and [FormComponents](https://github.com/entdec/form_components) for their forms, a dependency from GitHub: add `gem "form_components", github: "entdec/form_components"` to your Gemfile. Import Vario's JavaScript, which uses your app's Stimulus application (`window.Stimulus`) or starts one, and register FormComponents' controllers with it:

```js
// app/javascript/application.js
import "vario"
import { registerFormComponents } from "form_components"

registerFormComponents(window.Stimulus)
```

and add the styles of Vario and FormComponents to your Tailwind CSS:

```css
/* app/assets/tailwind/application.css */
@import "../builds/tailwind/vario";
@import "../builds/tailwind/form_components";
```

The icons are [Font Awesome](https://fontawesome.com)'s, which your app loads.

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
