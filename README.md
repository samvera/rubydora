# rubydora
[![CircleCI](https://circleci.com/gh/samvera/rubydora.svg?style=svg)](https://circleci.com/gh/samvera/rubydora)
[<img src="https://badge.fury.io/rb/rubydora.png" alt="Gem Version"/>](http://badge.fury.io/rb/rubydora)
[![Coverage Status](https://coveralls.io/repos/github/samvera/rubydora/badge.svg?branch=master)](https://coveralls.io/github/samvera/rubydora?branch=master)

Rubydora is a low-level Fedora Commons REST API consumer, providing direct
access to REST API methods, as well as a primitive ruby abstraction.

## Installation

```bash
gem install rubydora
```

## Examples

```
> repo = Rubydora.connect :url => 'http://localhost:8983/fedora', :user => 'fedoraAdmin', :password => 'fedoraAdmin'
=> #<Rubydora::Repository:0x101859538 @config={:url=>"http://localhost:8983/fedora", :user=>"fedoraAdmin", :password=>"fedoraAdmin"}> 

> obj = repo.find('test:1')
=> #<Rubydora::DigitalObject:0x101977230 @pid="test:1", @repository=#<Rubydora::Repository:0x1019beef0 @config={:user=>"fedoraAdmin", :url=>"http://localhost:8983/fedora", :password=>"fedora"}>> 

> obj.new?
=> true 

> obj = obj.save
=> #<Rubydora::DigitalObject:0x1017601b8 @pid="test:1", @repository=#<Rubydora::Repository:0x1018e3058 @config={:url=>"http://localhost:8983/fedora", :user=>"fedoraAdmin", :password=>"fedoraAdmin"}, @client=#<RestClient::Resource:0x101882910 @options={:user=>"fedoraAdmin", :password=>"fedoraAdmin"}, @block=nil, @url="http://localhost:8983/fedora">>> 

> obj.profile
=> {"objDissIndexViewURL"=>"http://localhost:8983/fedora/get/test:1/fedora-system:3/viewMethodIndex", "objLabel"=>"", "objModels"=>"info:fedora/fedora-system:FedoraObject-3.0", "objCreateDate"=>"2011-04-18T13:34:11.285Z", "objOwnerId"=>"fedoraAdmin", "objState"=>"A", "objItemIndexViewURL"=>"http://localhost:8983/fedora/get/test:1/fedora-system:3/viewItemIndex", "objLastModDate"=>"2011-04-18T13:47:30.110Z"} 

> obj.models
=> ["info:fedora/fedora-system:FedoraObject-3.0"] 

> obj.models << 'info:fedora/test:cmodel'
=> ["info:fedora/fedora-system:FedoraObject-3.0", "info:fedora/test:cmodel"]

> obj2 = repo.find('test:2')
=> [...]

> obj1.parts << obj2
=> [...]

> obj.datastreams
=> {"DC"=>#<Rubydora::Datastream:0x101860180 @dsid="DC" ...> }

> ds = obj.datastreams['File']
=> #<Rubydora::Datastream:0x1017f26a8 @dsid="File" ...>
> ds.controlGroup = 'R'
=> "R"
> ds.dsLocation = 'http://example.org/index.html'
=> "http://example.org/index.html"
> ds.dsLabel = 'Example redirect datastream'
=> "Example redirect datastream"
> ds.mimeType = 'text/html'
=> "text/html"
> ds.save 
=> #<Rubydora::Datastream:0x10177a568 @dsid="File" ...> 

> obj.datastreams
=> {"DC"=>#<Rubydora::Datastream:0x101860180 @dsid="DC" ..., "File"=>#<Rubydora::Datastream:0x10177a568 @dsid="File" ...>}

> obj.datastreams["File"].delete
=> true
> obj.datastreams["File"].new?
=> true
```

## Contributing to rubydora

*   Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
*   Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
*   Fork the project
*   Start a feature/bugfix branch
*   Commit and push until you are happy with your contribution
*   Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
*   Please try not to mess with the Rakefile, version, or history. If you want
    to have your own version, or is otherwise necessary, that is fine, but
    please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Chris Beer. See LICENSE.txt for further details.

