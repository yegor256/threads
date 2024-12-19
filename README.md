# Runs Code Block in Many Threads

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/threads)](http://www.rultor.com/p/yegor256/threads)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/threads/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/threads/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/threads.svg)](http://badge.fury.io/rb/threads)
[![Maintainability](https://api.codeclimate.com/v1/badges/24fc3acdf781d98b8749/maintainability)](https://codeclimate.com/github/yegor256/threads/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/threads/master/frames)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/threads.svg)](https://codecov.io/github/yegor256/threads?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/threads)](https://hitsofcode.com/view/github/yegor256/threads)

Read this blog post first: [Do You Test Ruby Code for Thread Safety?][blog]

When you need to test your code for thread safety, what do you do?
That's right, you just don't test it.
That's
[wrong](https://www.yegor256.com/2018/03/27/how-to-test-thread-safety.html)!
This simple gem helps you test your code
with just two additional lines of code.

First, install it:

```bash
gem install threads
```

Then, use it like this, to test your code from multiple
concurrently running threads:

```ruby
require 'threads'
Threads.new(5).assert do |i|
  puts "Hello from the thread no.#{i}"
end
```

You can put whatever you want into the block. The code will be executed
from five threads, concurrently.
You can also make sure the code block runs only a specific number of times
specifying the argument in the `assert` method (it can't be smaller
than the amount of threads):

```ruby
Threads.new(5).assert(20) do |i, r|
  puts "Hello from the thread no.#{i}, repetition no.#{r}"
end
```

You can also provide a logger, which will print exception backtraces.
It has to implement either method `error(msg)` or `puts(msg)`:

```ruby
Threads.new(5, log: STDOUT).assert do
  this_code_fails_for_sure
end
```

That's it.

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

[blog]: https://www.yegor256.com/2018/11/06/ruby-threads.html
