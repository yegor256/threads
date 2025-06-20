# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'
Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>=2.3'
  s.name = 'threads'
  s.version = '0.0.0'
  s.license = 'MIT'
  s.summary = 'Test threads'
  s.description = 'Ruby Gem to test a piece of code in concurrent threads'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'https://github.com/yegor256/threads'
  s.files = `git ls-files`.split($RS)
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md']
  s.add_dependency 'backtrace', '~>0'
  s.add_dependency 'concurrent-ruby', '~>1.0'
  s.metadata['rubygems_mfa_required'] = 'true'
end
