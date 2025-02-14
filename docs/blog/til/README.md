# Things I learned

## 2020 - what I've learned, done and thought

### IT, software, etc.

- proactive virtual assistants will change a lot of lives. [Building one with taskbutler](https://twitter.com/6uhrmittag/status/1274297420445290496) improved my life tremendously
- deploying a working prototype is better than deploying nothing
- I still prefer VMs(vagrant) over containers
- WSL is amazing
    - using GUI apps via x-server is already possible and will be amazing, once it's seamless 
- 4k is great for coding but negligible for movies
- Dolby Atmos for Headphones makes my 5.1 sound system jealous 
- cloud gaming - even with 500Mbit internet - is more frustrating than 30fps on low graphics
- all linux guides should include `moreutils`, `column` and `grep -E --color "WordToHighlight|$"`
- I still don't understand how Python should replace bash scripts

### life, health

- every movement involves moving weight and so, weight training improves every movement in life
    - carrying groceries is part of life and shouldn't be hard work. working out improves everyday life 
- a strict workout routine is easier to push through than random training  
- I still prefer real books over ebooks
- meditation and journaling helps, even when done sporadically
- remote work isn't as easy as it sounds
    - it's easier with a fun job and fun coworkers
- using Uber/caps to move(the household not the body) isn't fun, but works
- buying half the stuff for double the cost increases the quality of life without extra cost
- having strict routines doesn't make you a robot. It makes life much easier
- I sometimes miss the StartUp community for their love of trying new things, knowledge sharing and their never ending positivity
- I still don't really know how to connect with people
- I love sharing ideas and learnings and I should do it more
- I still look up to my mentors. More than ever
- I believe in Craftsmanship, the values of master craftsmen and in [Craftsmanship in Software](https://www.oreilly.com/library/view/apprenticeship-patterns/9780596806842/)
- starting to learn keyboard/piano brought back my joy of learning new(hard) things
- doing puzzles is a great way of doing something without doing anything
- lives can't be compared or rated. Don't rate lives of others and don't let others rate your life
- (I hope) getting 30 doesn't change anything

### home

- Bamboo Sheets are amazing. Bamboo feels like silk and is says cool, even in hot summer nights
- when in doubt, try Feng shui
- having tons of food in the fridge only produces more waste
- cordless vacuum cleaners are amazing and don't need >20min battery life
    - easy to use tools are key to developing routines
- decoration does improve the quality of life more than I thought
- I still can not believe how expensive "good" ergonomic office chairs are and why it's not normal to own one
- I think I prefer a loud neighbourhood over a quiet one. Are they quiet on purpose, or because they don't exist at all?

### personal projects, contributions, etc.

- r.i.p. [admindojo.org](https://twitter.com/6uhrmittag/status/1137113822609772554). I still believe in you, but hosting you on azure was a pain(but [CTFd](https://github.com/CTFd/CTFd) is a great platform to host Capture The Flag events).
- Taskbutler got a few cool updates
    - [proactive virtual assistant](https://github.com/6uhrmittag/taskbutler/tree/feature-assistentrelay)
    - [calculate the total of a shopping list](https://github.com/6uhrmittag/taskbutler/releases/tag/2.2.4)
    - [track incoming parcels(unfinished)](https://github.com/6uhrmittag/taskbutler/tree/feature_parceltracking)
- I made my first donation to a personal project, and it felt awesome
- I think I've found my first minor security bug, that allows checking the [actual existence of a bank account number by IBAN](https://twitter.com/6uhrmittag/status/1290898819375411200). They still haven't fixed it, so it might be intentional

## 10.05.20
!> Don't use exit(0) during development!

Exitcode 0 doesn't trigger the CI to fail! I used it during development and pushed it to production. Ouch.

## 15.01.20
!> When stuck while debugging: change user/privileges!

Shell Script failed. Tested it as root without any issues, changing the user to a non-root immediately gave enough hints to solve the issue.
Test with a non-root user when stuck!


## 18.12.19
!> Have replacement Parts on premise!

Non ATX PSU failed - older machine, no replacement on hand. 24h shipping was delayed; no 2. to ship in stock.
It can be cheaper to buy replacement parts you never need.

## 19.05.19
!> Don't be afraid! Just ship the MVP!

Even after I thought [admindojo.org](https://admindojo.org) was ready for public, it took me days to publish a post at [reddit](https://www.reddit.com/r/linuxadmin/comments/bq4v33/admindojoorg_handson_sysadmin_training_feedback/) or hackernews.
After finally publishing posts, it only got [a single comment at hackernews](https://news.ycombinator.com/item?id=19949053). I was so afraid, that I totally forgot how hard it is to even get feedback.
The feedback is worth it! Don't wait to get it.


## 01.05.19
!> Check the file format while debugging config files!

After debugging a configuration, I finally noticed that the configuration file had the wrong extension. Even when the content is almost the same - even Linux tools will handle `$.ini` different than  `$.conf`.


