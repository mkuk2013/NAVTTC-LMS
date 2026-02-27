-- Insert default row for exam_settings to prevent 406 Not Acceptable on .single() fetched
INSERT INTO public.exam_settings (id, is_active, exam_title, duration_minutes)
VALUES (1, false, 'Final Assessment', 60)
ON CONFLICT (id) DO NOTHING;

-- Also insert default row for arcade_config just in case
INSERT INTO public.arcade_config (id, is_unlocked)
VALUES (1, false)
ON CONFLICT (id) DO NOTHING;
