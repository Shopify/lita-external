# Lita::External

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/lita/external`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lita-external'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lita-external

## Usage

TODO: Write usage instructions here

## How it works

### Context

We are are very happy with Lita, and we are using it very extensively. So much that per moment it receive too much traffic and end up being limited by the CPU (parsing JSON webhooks mostly).

When this happen, HTTP and Chat requests start to be queued and Lita becomes unresponsive. So much that a simple ping can sometimes takes minutes.

### Proof of concept

As a PoC I implemented https://github.com/Shopify/lita-external. It's basically an abstract adapter that uses 2 Redis queues as communication mechanism.

Here's what it looks like conceptually:

```
             +------------+
             |            +-------------+
     +------->  Worker 2  |             |
     |       |            <--------+    |
     |       +------------+        |    |
     |                             |    |
+----+--+    +------------+   +----+----v----+    +-------------+    +------------+
|       |    |            +--->              +---->             |    |  Chat      |
| Nginx +---->  Worker 1  |   |    Redis     |    |   Master    <---->  Service   |
|       |    |            <---+              <----+             |    |            |
+-------+    +------------+   +--------------+    +-------------+    +------------+

```

- All the workers accepts HTTP requests
- Technically, the master also accept HTTP, but we simply don't send anything to it.
- We can add as many workers as we want, on multiple servers if needed.
- Incomming chat messages are serialized with `Marshal` and pushed in `lita:messages:inbound`
- All the workers maintain a `BLPOP` on `lita:messages:inbound`. When they are dispatched a message they process it in a thread pool.
- When workers need to send a chat message (or change topic or whatever), they push it in `lita:messages:outbound`.
- The master maintain a `BLPOP` on `lita:messages:outbound`, and simply send them to the chat service.

### Status

Since very recently we are running `lita-external` in production, without any problems so far (again it's very recent).

### Additional benefits

Beyond giving us more CPU capacity and horizontal capacity, it also allow give us:

  - Multi server capability which is not enough but a requirement for high availability of Lita. (It also require Redis failover and master election)
  - Zero downtime deploys. We can now restart lita without droping HTTP requests. We still have a very small chat downtime when restarting the master but that's more acceptable.
  

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/lita-external.

