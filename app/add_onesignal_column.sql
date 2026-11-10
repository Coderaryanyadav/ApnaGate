DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'profiles'
        AND column_name = 'onesignal_player_id'
    ) THEN
        ALTER TABLE profiles ADD COLUMN onesignal_player_id TEXT;
    END IF;
END
$$;
