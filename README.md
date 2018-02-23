## Piddles

A code problem, expressed as an API.

### Getting the code

All this was built on a Mac, and should run unmodified on any Linux/Unix system.

- Clone this repository: `git clone https://github.com/ctembreull/puddles.git`.
- Change to the resulting directory: `cd piddles`.
- Install dependencies: `bundle install`. This app was built with Ruby 2.3.1, which you may need to install before this succeeds.

### Test it!

Unit tests are provided, using RSpec. Run them using `rake spec`.

### Run it!

The API is runnable, using `rackup`. Once the app is running, you can test the API as follows:

```
curl -XGET http://localhost:9292/v1/store/availability

curl -XPOST http://localhost:9292/v1/store/purchase -d {}

curl -XGET http://localhost:9292/v2/store/availability

curl -XPOST http://localhost:9292/v2/store/purchase -d {}
```

### Hack it!

During development, I used Guard for hot-reloading my changes; you can do the same with `bundle exec guard`. The server will run, and changes to the code will reload the server immediately.

### What the heck did I do here?

At its heart, the problem presented was one of rate limiting. Normally, in an app intended for production, I'd solve this using Redis' ZSET functions, but as this was meant as a quick demonstration, I didn't feel that adding a dependency on Redis was a terribly good idea. Which left me two choices: a constantly-serializing data structure, or something in-memory. It occurred to me that the problem was structured around versions - the first being the single-tester structure, and the second being when all of Piddles' friends got hired on, providing multiple testers. To me, that seemed like a really great basis for an API, so I chose the route of an in-memory datastore. You can see that - and all of the code to work with it - in [lib/hydrant.rb](https://github.com/ctembreull/piddles/blob/master/lib/hydrant.rb). There's a lot of comments, especially where I've leaned a bit on Ruby magic to do things.

#### A brief note on synchronicity:

It was easily the Police's best album. But in terms of this project, I didn't have to worry too much about multiple clients making requests against the queue here, because Ruby is single-threaded and synchronous (some implementations support async and multithreading but stock Ruby doesn't). Had I elected to write this project in, say, Node - or to actually use an external queue server - I would have had to enforce some sort of flow by using a lock variable, and requiring that any request wait to get the lock before making any requests of the queue. There's lots of ways to enforce things like this, e.g. in Ruby using EventMachine, but they all fall outside the scope of a code sample project, so I sort of handwaved the whole thing and left this note instead.

#### Hydrant::Queue

Beyond the very slight metaprogramming in the constructor, HydrantQueue has some interesting bits. the `period_count` method reduces the entries in the SortedSet for any given tester to a number, indicating how many requests have been processed in the provided time period. `period_all_count` is just a shorthand that runs `period_count` for every tester queue, and formats the results in a useful way. You might notice that the default `tester` argument is "piddles", which is a way of faking the simpler structure that we had when we only had a single tester. 

A bit of a word on that: I probably could have changed the globals in `config/application.rb` so that there was a `HydrantQueueV1` (just a plain SortedSet) and a `HydrantQueueV2`, and had the appropriate version methods reference the appropriate structure. But this version is a bit more tightly coupled, so we settle for V1 methods only accessing a single queue inside the more complex HydrantQueue structure. One late-breaking change: I did abstract out the default-tester arguments for these methods to a constant living with the other bits of configuration in `config/application.rb`

#### V1

When Piddles is our only tester, we simply need to read from his queue to see how many requests he's serviced in the last 5 minutes. If it's more than 0, then we return false. Likewise, we make sure that he hasn't serviced more than 5 requests in the last hour (rolling). 
All of this is actually done in `can_sell_hydrant`, where we make calls to `period_count`, do a bit of checking on the result, and return true or false. The `sell_hydrant` method only has to call `can_sell_hydrant` for its own go/no-go testing, and then if the result is true, to push a service record onto Piddles' queue.

#### V2

Once Piddles' friends have been hired, though, things get slightly more interesting. We add an `available_testers` method, which calls the more powerful `period_all_count`, once for each condition we want to test. Since we get back a hash, keyed by tester name, we can then produce a pair of arrays containing the names of testers who fulfill either condition, and we can do an intersection on those two arrays to get the names of every tester who is available to test a hydrant. `any_can_sell_hydrant` simply checks that the intersection of available testers is not empty, while `any_sell_hydrant` gets back the list of available testers and selects one at random, then specifically inserts the service record into that tester's queue.

