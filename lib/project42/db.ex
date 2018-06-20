defmodule Data do
    use GenServer
    def start_link do
        hashtags = :ets.new(:user_lookup, [:bag, :named_table, :public])
        mentions = :ets.new(:user, [:bag, :named_table, :public])
        tweets = :ets.new(:tweet, [:bag, :named_table, :public])
        subscribers = :ets.new(:sub,[:bag, :named_table, :public])
        subscribed = :ets.new(:subed,[:bag, :named_table, :public])
        {:ok, pid} = GenServer.start_link(__MODULE__, {hashtags, mentions, tweets, subscribers, subscribed}, name: Database)
        :global.register_name(:database, pid)
    end

    def init(state) do
        {:ok, state}
    end

    def add_tweet(pid,tweet,user_id) do
        {hashtags,mentions,tweets,subscribers,subscribed} = get_state(pid)
        :ets.insert(tweets, {user_id, tweet})
        #IO.inspect :ets.lookup(tweets,user_id)
        list = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet)
        #IO.inspect list
        if(list !=nil) do
            Enum.each list, fn(x) ->
                #IO.inspect x
                add_hashtags(pid, Enum.at(x,0), tweet) end
        end
        list2 = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet)
        if(list2 !=nil) do
            Enum.each list2, fn(x) ->
                add_mentions(pid, Enum.at(x,0), tweet) end
        end
        GenServer.cast(pid,{:update,hashtags,mentions,tweets,subscribers, subscribed})
    end


    def add_hashtags(pid, hashtag,tweet) do
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        :ets.insert(hashtags, {hashtag, tweet})
        GenServer.cast(pid,{:update,hashtags,mentions,tweets,subscribers, subscribed})
    end

    def add_mentions(pid, name,tweet) do
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        :ets.insert(mentions, {name, tweet})
        GenServer.cast(pid,{:update,hashtags,mentions,tweets,subscribers, subscribed})
    end

    def add_subscribers(user_id, subscriber_id) do
        pid = :global.whereis_name(:database)
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        :ets.insert(subscribers, {user_id, subscriber_id})
        GenServer.cast(pid,{:update,hashtags,mentions,tweets,subscribers, subscribed})
    end

    def add_subscribed_to(subscriber_id,user_id) do
        pid = :global.whereis_name(:database)
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        :ets.insert(subscribed, {subscriber_id, user_id})
        GenServer.cast(pid,{:update,hashtags,mentions,tweets,subscribers, subscribed})
    end

    def get_mentions(pid,name) do
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        list = :ets.lookup(mentions, name)

    end

    def get_hashtags(pid, hashtag) do
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        list = :ets.lookup(hashtags, hashtag)
        

    end

    def get_tweets(pid, user_id) do
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        list = :ets.lookup(tweets, user_id)
        #IO.inspect list
    end

    def get_all_tweets(user_id) do
        list = get_subscribed_to(user_id)
        
        end
        


    def get_subscribers(pid, user_id) do
      pid = :global.whereis_name(:database)
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        list = :ets.lookup(subscribers, user_id)
    end

    def get_subscribed_to(subscriber_id) do
        pid = :global.whereis_name(:database)
        {hashtags,mentions,tweets,subscribers, subscribed} = get_state(pid)
        list = :ets.lookup(subscribed, subscriber_id)
    end

    def handle_cast({:update,hashtags,mentions,tweets,subscribers, subscribed},state) do
        {hashtags,mentions,tweets,subscribers, subscribed} = state
        state = {hashtags,mentions,tweets,subscribers, subscribed}
        {:noreply,state}
    end

    def get_state(pid) do
        :global.sync
        GenServer.call(pid,:get_all)
    end

    def handle_cast({:update_sub,user_id, sub_id},state) do
        {hashtags,mentions,tweets,subscribers, subscribed} = state
        :ets.insert(subscribers,{user_id,sub_id})
        state = {hashtags,mentions,tweets,subscribers, subscribed}
        {:noreply,state}
    end

    def handle_cast({:update_tweets,user_id, tweet},state) do
        {hashtags,mentions,tweets,subscribers, subscribed} = state
        
        :ets.insert(tweets, {user_id, tweet})
        #IO.inspect :ets.lookup(tweets,user_id)
        list = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet)
        #IO.inspect list
        if(list !=nil) do
            Enum.each list, fn(x) ->
                #IO.inspect x
                :ets.insert(hashtags, {Enum.at(x,0), tweet}) end
        end
        list2 = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet)
        if(list2 !=nil) do
            Enum.each list2, fn(x) ->
                :ets.insert(mentions, {Enum.at(x,0), tweet}) end
        end

        state = {hashtags,mentions,tweets,subscribers, subscribed}
        #IO.inspect tweets
        {:noreply,state}
    end

    def handle_call(:get_all, _from, state) do
        {:reply, state, state}
    end
end
