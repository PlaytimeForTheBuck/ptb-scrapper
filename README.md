### DB Scrapper for Playtime For The Buck

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

And you know what? This simplicity feels good.

And I'm probably going to end using Ruby 1.8.7 so I can use cronjobs on my shitty webserver. Oh well.