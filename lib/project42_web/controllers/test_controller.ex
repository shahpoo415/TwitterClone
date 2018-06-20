defmodule Project42Web.TestController do
    use Project42Web, :controller
  
    def show(conn,%{"id" => id,"sub"=>sub}) do
        
        pid = :global.whereis_name(:database)
        Data.add_subscribers(id,sub)
        Data.add_tweet(pid,"hi there",id)
        Data.add_tweet(pid,"hi there 2",id)
        Data.add_tweet(pid,"hi there 3",id)
        Data.add_tweet(pid,"hi there 4",id)
        
        list = Data.get_tweets(pid,id)
        IO.inspect list
        Enum.reduce list, " ", fn(num, acc) ->elem(num,1) <>" "<> acc end
        text conn, "user_id: #{id}, tweet: #{elem(Enum.at(list,0),1)}"
    end
    
  end
  