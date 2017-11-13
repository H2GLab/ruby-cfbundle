# cfbundle

CFBundle is a ruby library for reading macOS and iOS bundles (including zipped bundles and `.ipa` files).

## Installation

CFBundle is available on RubyGems:

```sh
gem install cfbundle
```

Or in your Gemfile:

```
gem 'cfbundle'
```

## Usage

```ruby
require 'cfbundle'

result = CFBundle::Bundle.open('path/to/App.app') do |bundle|
  name = bundle.name
  version = "#{bundle.release_version} (#{bundle.build_version})"
  name + ' ' + version
end
```

You can also call `open` without a block. In that case, the methods returns the bundle and you need to close it when it is no longer needed.

```ruby
bundle = CFBundle::Bundle.open('path/to/App.app')
# result = ...
bundle.close
```

## ZIP archives and `.ipa` files

CFBundle can read bundles contained in ZIP archives or `.ipa` files when the Rubyzip gem is loaded. You may pass the path to the ZIP archive on the file system or an `IO` object (or any object that behaves like an `IO`). CFBundle expects the bundle to be at the root of the archive or inside a directory named `Payload`.

```ruby
require 'cfbundle'
require 'zip'

CFBundle::Bundle.open('path/to/App.ipa') do |bundle|
  # ...
end
```

## License

CFBundle is distributed under the MIT license. See [LICENSE](LICENSE) file.
