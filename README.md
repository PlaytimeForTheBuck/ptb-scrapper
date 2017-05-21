## ⚠️ Deprecated ⚠️

Inspired by the essence of this project I created [GGFilter.com](http://ggfilter.com/), which has similar goals of helping you find games, but with a greater scope and infrastructure.

---

### DB Scrapper for PlaytimeForTheBuck

This database scrapper sails across the Ste*m oceans and picks up information about the games.

As of now it scraps 3 different pages. The games-list page, the game page, and the reviews pages.

So this is the information that scraps for each game:

- Name
- Launch Date
- Meta Score
- Positive Reviews, with its respective play time
- Negative Reviews, with its respective play time
- Price of the game
- Sale price of the game
- Categories / Tags

With this info we can do a lot of analysis!

What's on the roadmap? I want to generate an index of hardware requirements for each game, thus allowing people to find games based on hardware requirements.

### About the project

At first I thought about doing the server on Rails. And I did. And did the testing on Rails and all the stuff. But then, I thought... wait a minute? Why do I want Rails here? Isn't it kind of overkill? I'm going to do the front end separatedly anyway.

And so I decided to go for Sinatra.

And I thought... wait a minute? Why do I use Sinatra? I mean, the DB is going to be scrapped every hour or so, and I'm going to be serving just static assets. Besides, to host a Sinatra app, the only free option is self host, or free Heroku.

And so I decided to go for an good old apache server and MySQL with Ruby and Activerecord.

And I thought... wait a minute? Why do I use MySQL? I maen, the whole DB is going to be practically rescrapped every hour and I'm not going to search or anything, just get all the rows, and save all the rows.

And so I decided to go for Apache and Ruby with Activerecord and saving to a plain json file.

And I thought... wait a minute? This shitty hosting I have for other things only supports Ruby 1.8.7, that sucks. 

And so I decided to go for Ruby and Activerecord, just running in my computer with a cronjob in my own computer to push trough FTP.

And I thought... waint a minute? I'm only using Activerecord validations, and these validations are really basic. You know what, fuck ActiveRecord, I'm gonna use plain old Ruby without all the bells and whistles from Rails.

And so I decided to just use Ruby and a basic app structure.

And after I got knee-deep into the project I realized I SHOULD have used AT LEAST activerecord, in case I decided to migrate to a non-static server. So I refactored my models to use ActiveRecord and Sqlite!

And then I had to refactor again so I could use this project as a GEM! That took me hours, but it was totally worth it, because if I decide to go the Sinatra, or the Rails way, I don't need to change anything!

### About the human

Made by Zequez on it's free time. GPLv2 licence.

If you have any idea, just shoot me here, or on Reddit, or wherever you wish. But don't literally shoot me.



