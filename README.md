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

At its heart, the problem presented was one of rate limiting. Normally, I'd solve this using Redis' ZSET functions, but as this was meant as a quick demonstration, I didn't feel that adding a dependency on Redis was a terribly good idea. Which left me two choices: a constantly-serializing data structure, or something in-memory. It occurred to me that the problem was structured around versions - the first being the single-tester structure, and the second being when all of Piddles' friends got hired on, providing multiple testers. To me, that seemed like a really great basis for an API, so I chose the route of an in-memory datastore. You can see that - and all of the code to work with it - in [lib/hydrant.rb](https://github.com/ctembreull/piddles/blob/master/lib/hydrant.rb). There's a lot of comments, especially where I've leaned a bit on Ruby magic to do things.

#### Hydrant::Queue

Beyond the very slight metaprogramming in the constructor, HydrantQueue has some interesting bits. the `period_count` method reduces the entries in the SortedSet for any given tester to a number, indicating how many requests have been processed in the provided time period.
`period_all_count` is just a shorthand that runs `period_count` for every tester queue, and formats the results in a useful way. You might notice that the default `tester` argument is "piddles", which is a way of faking the simpler structure that we had when we only had a single tester. 

#### V1

When Piddles is our only tester, we simply need to read from his queue to see how many requests he's serviced in the last 5 minutes. If it's more than 0, then we return false. Likewise, we make sure that he hasn't serviced more than 6 requests in the last hour (rolling). 
All of this is actually done in `can_sell_hydrant`, where we make calls to `period_count`, do a bit of checking on the result, and return true or false. The `sell_hydrant` method only has to call `can_sell_hydrant` for its own testing, and then if the result is true, to push a service record onto Piddles' queue.

#### V2

Once Piddles' friends have been hired, though, things get slightly more interesting. We add an `available_testers` method, which calls the more-powerful `period_all_count`, once for each condition we want to test. Since we get back a hash, keyed by tester name, we can then produce a pair of arrays containing the names of testers who fulfill either condition, and we can do an intersection on those two arrays to get the names of every tester who is available to test a hydrant. `any_can_sell_hydrant` simply checks that the intersection of available testers is not empty, while `any_sell_hydrant` gets back the list of available testers and selects one at random, then specifically inserts the service record into that tester's queue.

