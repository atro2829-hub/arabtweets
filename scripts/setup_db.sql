-- Arabtweets Database Schema for Supabase
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username      VARCHAR(30) UNIQUE NOT NULL,
    display_name  VARCHAR(60) NOT NULL DEFAULT '',
    bio           TEXT DEFAULT '',
    avatar_url    TEXT DEFAULT '',
    cover_url     TEXT DEFAULT '',
    location      VARCHAR(100) DEFAULT '',
    website       TEXT DEFAULT '',
    is_verified   BOOLEAN DEFAULT FALSE,
    theme         VARCHAR(10) DEFAULT 'light',
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. TWEETS
CREATE TABLE IF NOT EXISTS tweets (
    id            BIGSERIAL PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content       TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 500),
    media_urls    TEXT[] DEFAULT '{}',
    parent_id     BIGINT REFERENCES tweets(id) ON DELETE CASCADE,
    is_quote      BOOLEAN DEFAULT FALSE,
    quote_tweet_id BIGINT REFERENCES tweets(id) ON DELETE SET NULL,
    reply_count   INT DEFAULT 0,
    retweet_count INT DEFAULT 0,
    like_count    INT DEFAULT 0,
    view_count    INT DEFAULT 0,
    bookmark_count INT DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_tweets_user_id ON tweets(user_id);
CREATE INDEX idx_tweets_parent_id ON tweets(parent_id);
CREATE INDEX idx_tweets_created_at ON tweets(created_at DESC);

-- 3. RETWEETS
CREATE TABLE IF NOT EXISTS retweets (
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tweet_id      BIGINT NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, tweet_id)
);

-- 4. LIKES
CREATE TABLE IF NOT EXISTS likes (
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tweet_id      BIGINT NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, tweet_id)
);

-- 5. BOOKMARKS
CREATE TABLE IF NOT EXISTS bookmarks (
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tweet_id      BIGINT NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, tweet_id)
);

-- 6. FOLLOWS
CREATE TABLE IF NOT EXISTS follows (
    follower_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    following_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)
);

-- 7. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id            BIGSERIAL PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    from_user_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type          VARCHAR(20) NOT NULL CHECK (type IN ('like','retweet','follow','reply','mention','message')),
    tweet_id      BIGINT REFERENCES tweets(id) ON DELETE SET NULL,
    is_read       BOOLEAN DEFAULT FALSE,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_user_id ON notifications(user_id, created_at DESC);

-- 8. CONVERSATIONS
CREATE TABLE IF NOT EXISTS conversations (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_read_at   TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id)
);

-- 9. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
    id              BIGSERIAL PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content         TEXT NOT NULL CHECK (char_length(content) > 0),
    media_url       TEXT,
    is_read         BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id, created_at DESC);

-- 10. HASHTAGS
CREATE TABLE IF NOT EXISTS hashtags (
    id            SERIAL PRIMARY KEY,
    tag           VARCHAR(100) UNIQUE NOT NULL,
    tweet_count   INT DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS tweet_hashtags (
    tweet_id  BIGINT NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
    hashtag_id INT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (tweet_id, hashtag_id)
);

-- 11. MENTIONS
CREATE TABLE IF NOT EXISTS mentions (
    tweet_id        BIGINT NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
    mentioned_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (tweet_id, mentioned_user_id)
);

-- 12. BLOCKS
CREATE TABLE IF NOT EXISTS blocks (
    blocker_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tweets ENABLE ROW LEVEL SECURITY;
ALTER TABLE retweets ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tweet_hashtags ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "Profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Profiles_delete" ON profiles FOR DELETE USING (auth.uid() = id);

CREATE POLICY "Tweets_select" ON tweets FOR SELECT USING (true);
CREATE POLICY "Tweets_insert" ON tweets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tweets_update" ON tweets FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Tweets_delete" ON tweets FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Likes_select" ON likes FOR SELECT USING (true);
CREATE POLICY "Likes_insert" ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Likes_delete" ON likes FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Retweets_select" ON retweets FOR SELECT USING (true);
CREATE POLICY "Retweets_insert" ON retweets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Retweets_delete" ON retweets FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Bookmarks_select" ON bookmarks FOR SELECT USING (true);
CREATE POLICY "Bookmarks_insert" ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Bookmarks_delete" ON bookmarks FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Follows_select" ON follows FOR SELECT USING (true);
CREATE POLICY "Follows_insert" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Follows_delete" ON follows FOR DELETE USING (auth.uid() = follower_id);

CREATE POLICY "Notifs_select" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Notifs_insert" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Notifs_update" ON notifications FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Conv_select" ON conversations FOR SELECT USING (EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = conversations.id AND user_id = auth.uid()));
CREATE POLICY "Conv_insert" ON conversations FOR INSERT WITH CHECK (true);
CREATE POLICY "Conv_update" ON conversations FOR UPDATE USING (EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = conversations.id AND user_id = auth.uid()));

CREATE POLICY "CP_select" ON conversation_participants FOR SELECT USING (EXISTS (SELECT 1 FROM conversation_participants cp WHERE cp.conversation_id = conversation_participants.conversation_id AND cp.user_id = auth.uid()));
CREATE POLICY "CP_insert" ON conversation_participants FOR INSERT WITH CHECK (true);
CREATE POLICY "CP_update" ON conversation_participants FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Msg_select" ON messages FOR SELECT USING (EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()));
CREATE POLICY "Msg_insert" ON messages FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = messages.conversation_id AND user_id = auth.uid()));
CREATE POLICY "Msg_update" ON messages FOR UPDATE USING (auth.uid() = sender_id);

CREATE POLICY "Hashtags_select" ON hashtags FOR SELECT USING (true);
CREATE POLICY "Hashtags_insert" ON hashtags FOR INSERT WITH CHECK (true);
CREATE POLICY "Hashtags_update" ON hashtags FOR UPDATE WITH CHECK (true);

CREATE POLICY "TH_select" ON tweet_hashtags FOR SELECT USING (true);
CREATE POLICY "TH_insert" ON tweet_hashtags FOR INSERT WITH CHECK (true);

CREATE POLICY "Mentions_select" ON mentions FOR SELECT USING (true);
CREATE POLICY "Mentions_insert" ON mentions FOR INSERT WITH CHECK (true);

CREATE POLICY "Blocks_select" ON blocks FOR SELECT USING (auth.uid() = blocker_id);
CREATE POLICY "Blocks_insert" ON blocks FOR INSERT WITH CHECK (auth.uid() = blocker_id);
CREATE POLICY "Blocks_delete" ON blocks FOR DELETE USING (auth.uid() = blocker_id);

-- RPC FUNCTIONS
CREATE OR REPLACE FUNCTION get_feed(p_user_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id BIGINT, user_id UUID, content TEXT, media_urls TEXT[], parent_id BIGINT,
    is_quote BOOLEAN, quote_tweet_id BIGINT, reply_count INT, retweet_count INT,
    like_count INT, view_count INT, bookmark_count INT, created_at TIMESTAMPTZ,
    username VARCHAR(30), display_name VARCHAR(60), avatar_url TEXT, is_verified BOOLEAN,
    is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN, is_following BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.user_id, t.content, t.media_urls, t.parent_id, t.is_quote,
        t.quote_tweet_id, t.reply_count, t.retweet_count, t.like_count, t.view_count,
        t.bookmark_count, t.created_at, p.username, p.display_name, p.avatar_url, p.is_verified,
        EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.id AND user_id = p_user_id),
        EXISTS(SELECT 1 FROM retweets WHERE tweet_id = t.id AND user_id = p_user_id),
        EXISTS(SELECT 1 FROM bookmarks WHERE tweet_id = t.id AND user_id = p_user_id),
        EXISTS(SELECT 1 FROM follows WHERE follower_id = p_user_id AND following_id = t.user_id)
    FROM tweets t
    JOIN profiles p ON t.user_id = p.id
    WHERE (t.user_id = p_user_id OR EXISTS (SELECT 1 FROM follows WHERE follower_id = p_user_id AND following_id = t.user_id))
    AND t.parent_id IS NULL
    ORDER BY t.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_tweet_replies(p_tweet_id BIGINT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id BIGINT, user_id UUID, content TEXT, media_urls TEXT[], parent_id BIGINT,
    reply_count INT, retweet_count INT, like_count INT, view_count INT, bookmark_count INT,
    created_at TIMESTAMPTZ, username VARCHAR(30), display_name VARCHAR(60), avatar_url TEXT, is_verified BOOLEAN,
    is_liked BOOLEAN, is_retweeted BOOLEAN, is_bookmarked BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.user_id, t.content, t.media_urls, t.parent_id,
        t.reply_count, t.retweet_count, t.like_count, t.view_count, t.bookmark_count, t.created_at,
        p.username, p.display_name, p.avatar_url, p.is_verified,
        EXISTS(SELECT 1 FROM likes WHERE tweet_id = t.id AND user_id = COALESCE((SELECT user_id FROM tweets WHERE id = p_tweet_id), '00000000-0000-0000-0000-000000000000'::UUID)),
        false, false
    FROM tweets t
    JOIN profiles p ON t.user_id = p.id
    WHERE t.parent_id = p_tweet_id
    ORDER BY t.created_at ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION search_tweets_fn(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id BIGINT, user_id UUID, content TEXT, media_urls TEXT[],
    like_count INT, retweet_count INT, reply_count INT, created_at TIMESTAMPTZ,
    username VARCHAR(30), display_name VARCHAR(60), avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.user_id, t.content, t.media_urls,
        t.like_count, t.retweet_count, t.reply_count, t.created_at,
        p.username, p.display_name, p.avatar_url
    FROM tweets t JOIN profiles p ON t.user_id = p.id
    WHERE t.content ILIKE '%' || p_query || '%'
    ORDER BY t.created_at DESC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION search_users_fn(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id UUID, username VARCHAR(30), display_name VARCHAR(60), avatar_url TEXT,
    bio TEXT, is_verified BOOLEAN, followers_count INT, following_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.username, p.display_name, p.avatar_url, p.bio, p.is_verified,
        (SELECT COUNT(*) FROM follows WHERE following_id = p.id),
        (SELECT COUNT(*) FROM follows WHERE follower_id = p.id)
    FROM profiles p
    WHERE p.username ILIKE '%' || p_query || '%' OR p.display_name ILIKE '%' || p_query || '%'
    ORDER BY p.username LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_trending_hashtags(p_limit INT DEFAULT 20)
RETURNS TABLE (id INT, tag VARCHAR(100), tweet_count INT) AS $$
BEGIN
    RETURN QUERY SELECT h.id, h.tag, h.tweet_count
    FROM hashtags h ORDER BY h.tweet_count DESC LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_notifications(p_user_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id BIGINT, from_user_id UUID, type VARCHAR(20), tweet_id BIGINT,
    is_read BOOLEAN, created_at TIMESTAMPTZ,
    from_username VARCHAR(30), from_display_name VARCHAR(60), from_avatar_url TEXT, tweet_content TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT n.id, n.from_user_id, n.type, n.tweet_id, n.is_read, n.created_at,
        fp.username, fp.display_name, fp.avatar_url, t.content
    FROM notifications n
    JOIN profiles fp ON n.from_user_id = fp.id
    LEFT JOIN tweets t ON n.tweet_id = t.id
    WHERE n.user_id = p_user_id
    ORDER BY n.created_at DESC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE (
    conversation_id UUID, other_user_id UUID, other_username VARCHAR(30),
    other_display_name VARCHAR(60), other_avatar_url TEXT,
    last_message TEXT, last_message_at TIMESTAMPTZ, unread_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT cp.conversation_id, other_p.id, other_p.username, other_p.display_name,
        other_p.avatar_url, last_msg.content, last_msg.created_at,
        (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = cp.conversation_id AND m.is_read = false AND m.sender_id != p_user_id)
    FROM conversation_participants cp
    JOIN profiles other_p ON other_p.id != p_user_id
    JOIN conversation_participants cp2 ON cp2.conversation_id = cp.conversation_id AND cp2.user_id = other_p.id
    LEFT JOIN LATERAL (SELECT content, created_at FROM messages WHERE conversation_id = cp.conversation_id ORDER BY created_at DESC LIMIT 1) last_msg ON true
    WHERE cp.user_id = p_user_id
    ORDER BY last_message_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_conversation_messages(p_conversation_id UUID, p_limit INT DEFAULT 50, p_offset INT DEFAULT 0)
RETURNS TABLE (
    id BIGINT, sender_id UUID, content TEXT, media_url TEXT, is_read BOOLEAN,
    created_at TIMESTAMPTZ, sender_username VARCHAR(30), sender_avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT m.id, m.sender_id, m.content, m.media_url, m.is_read, m.created_at,
        p.username, p.avatar_url
    FROM messages m JOIN profiles p ON m.sender_id = p.id
    WHERE m.conversation_id = p_conversation_id
    ORDER BY m.created_at ASC LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION toggle_like(p_user_id UUID, p_tweet_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM likes WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
        UPDATE tweets SET like_count = GREATEST(like_count - 1, 0) WHERE id = p_tweet_id;
        RETURN false;
    ELSE
        INSERT INTO likes (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
        UPDATE tweets SET like_count = like_count + 1 WHERE id = p_tweet_id;
        INSERT INTO notifications (user_id, from_user_id, type, tweet_id)
        SELECT t.user_id, p_user_id, 'like', p_tweet_id FROM tweets t WHERE t.id = p_tweet_id AND t.user_id != p_user_id ON CONFLICT DO NOTHING;
        RETURN true;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION toggle_retweet(p_user_id UUID, p_tweet_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM retweets WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM retweets WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
        UPDATE tweets SET retweet_count = GREATEST(retweet_count - 1, 0) WHERE id = p_tweet_id;
        RETURN false;
    ELSE
        INSERT INTO retweets (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
        UPDATE tweets SET retweet_count = retweet_count + 1 WHERE id = p_tweet_id;
        INSERT INTO notifications (user_id, from_user_id, type, tweet_id)
        SELECT t.user_id, p_user_id, 'retweet', p_tweet_id FROM tweets t WHERE t.id = p_tweet_id AND t.user_id != p_user_id ON CONFLICT DO NOTHING;
        RETURN true;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION toggle_bookmark(p_user_id UUID, p_tweet_id BIGINT) RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM bookmarks WHERE user_id = p_user_id AND tweet_id = p_tweet_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM bookmarks WHERE user_id = p_user_id AND tweet_id = p_tweet_id;
        UPDATE tweets SET bookmark_count = GREATEST(bookmark_count - 1, 0) WHERE id = p_tweet_id;
        RETURN false;
    ELSE
        INSERT INTO bookmarks (user_id, tweet_id) VALUES (p_user_id, p_tweet_id);
        UPDATE tweets SET bookmark_count = bookmark_count + 1 WHERE id = p_tweet_id;
        RETURN true;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION toggle_follow(p_follower_id UUID, p_following_id UUID) RETURNS BOOLEAN AS $$
DECLARE v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = p_follower_id AND following_id = p_following_id) INTO v_exists;
    IF v_exists THEN
        DELETE FROM follows WHERE follower_id = p_follower_id AND following_id = p_following_id;
        RETURN false;
    ELSE
        INSERT INTO follows (follower_id, following_id) VALUES (p_follower_id, p_following_id);
        INSERT INTO notifications (user_id, from_user_id, type) VALUES (p_following_id, p_follower_id, 'follow') ON CONFLICT DO NOTHING;
        RETURN true;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_tweet(
    p_user_id UUID, p_content TEXT, p_media_urls TEXT[] DEFAULT '{}',
    p_parent_id BIGINT DEFAULT NULL, p_quote_tweet_id BIGINT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE v_tweet_id BIGINT; v_tag_text TEXT;
BEGIN
    INSERT INTO tweets (user_id, content, media_urls, parent_id, quote_tweet_id)
    VALUES (p_user_id, p_content, p_media_urls, p_parent_id, p_quote_tweet_id)
    RETURNING id INTO v_tweet_id;
    
    FOR v_tag_text IN SELECT DISTINCT (regexp_matches(p_content, '#([a-zA-Z0-9_\u0600-\u06FF]+)', 'g'))[1] LOOP
        INSERT INTO hashtags (tag) VALUES (v_tag_text) ON CONFLICT (tag) DO NOTHING;
        INSERT INTO tweet_hashtags (tweet_id, hashtag_id)
        SELECT v_tweet_id, h.id FROM hashtags h WHERE h.tag = v_tag_text ON CONFLICT DO NOTHING;
        UPDATE hashtags SET tweet_count = tweet_count + 1 WHERE tag = v_tag_text;
    END LOOP;
    
    FOR v_tag_text IN SELECT DISTINCT (regexp_matches(p_content, '@([a-zA-Z0-9_]+)', 'g'))[1] LOOP
        INSERT INTO mentions (tweet_id, mentioned_user_id)
        SELECT v_tweet_id, p.id FROM profiles p WHERE p.username = v_tag_text ON CONFLICT DO NOTHING;
        INSERT INTO notifications (user_id, from_user_id, type, tweet_id)
        SELECT p.id, p_user_id, 'mention', v_tweet_id FROM profiles p WHERE p.username = v_tag_text AND p.id != p_user_id ON CONFLICT DO NOTHING;
    END LOOP;
    
    IF p_parent_id IS NOT NULL THEN
        UPDATE tweets SET reply_count = reply_count + 1 WHERE id = p_parent_id;
        INSERT INTO notifications (user_id, from_user_id, type, tweet_id)
        SELECT t.user_id, p_user_id, 'reply', v_tweet_id FROM tweets t WHERE t.id = p_parent_id AND t.user_id != p_user_id ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN v_tweet_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_notifications_read(p_user_id UUID) RETURNS VOID AS $$
BEGIN
    UPDATE notifications SET is_read = true WHERE user_id = p_user_id AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('covers', 'covers', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('media', 'media', true) ON CONFLICT DO NOTHING;

CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update avatars" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view covers" ON storage.objects FOR SELECT USING (bucket_id = 'covers');
CREATE POLICY "Users can upload covers" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'covers' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update covers" ON storage.objects FOR UPDATE USING (bucket_id = 'covers' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view media" ON storage.objects FOR SELECT USING (bucket_id = 'media');
CREATE POLICY "Users can upload media" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'media' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update media" ON storage.objects FOR UPDATE USING (bucket_id = 'media' AND auth.uid()::text = (storage.foldername(name))[1]);