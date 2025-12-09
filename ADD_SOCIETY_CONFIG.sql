CREATE TABLE IF NOT EXISTS public.society_config (
  key TEXT PRIMARY KEY,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE society_config ENABLE ROW LEVEL SECURITY;

-- Allow Public Read (or Authenticated Read)
CREATE POLICY "Everyone can read config" ON society_config
  FOR SELECT USING (true);

-- Allow Admin Update
CREATE POLICY "Admins can update config" ON society_config
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Seed Default Config if not exists
INSERT INTO public.society_config (key, value) VALUES 
('wings', '["A", "B"]'::jsonb),
('floors', '12'::jsonb),
('flats_per_floor', '4'::jsonb)
ON CONFLICT (key) DO NOTHING;
