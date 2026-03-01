-- Supabase Automatic User Deletion (Cascading Deletes) Repair Script --

-- 1. PROFILES Table
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey
  FOREIGN KEY (id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 2. GAMIFICATION (User Progress)
ALTER TABLE public.user_progress DROP CONSTRAINT IF EXISTS user_progress_user_id_fkey;
ALTER TABLE public.user_progress
  ADD CONSTRAINT user_progress_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 3. MEDICATIONS Table
ALTER TABLE public.medications DROP CONSTRAINT IF EXISTS medications_user_id_fkey;
ALTER TABLE public.medications
  ADD CONSTRAINT medications_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 4. FOOD LOGS Table
ALTER TABLE public.food_logs DROP CONSTRAINT IF EXISTS food_logs_user_id_fkey;
ALTER TABLE public.food_logs
  ADD CONSTRAINT food_logs_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 5. CHAT HISTORY Table
ALTER TABLE public.chat_history DROP CONSTRAINT IF EXISTS chat_history_user_id_fkey;
ALTER TABLE public.chat_history
  ADD CONSTRAINT chat_history_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 6. CHECK-INS Table
ALTER TABLE public.check_ins DROP CONSTRAINT IF EXISTS check_ins_user_id_fkey;
ALTER TABLE public.check_ins
  ADD CONSTRAINT check_ins_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;
